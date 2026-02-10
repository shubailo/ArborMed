import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/stats_provider.dart';
import '../../../services/api_service.dart';
import '../../../theme/cozy_theme.dart';
import 'dart:convert';
import '../../../widgets/admin/dual_language_field.dart';
import '../../../widgets/admin/dynamic_option_list.dart';
import '../../../services/translation_service.dart';
import 'question_preview_card.dart';
import 'admin_phone_preview.dart';

class QuestionEditorDialog extends StatefulWidget {
  final AdminQuestion? question;
  final List<dynamic> topics; // Accepted topics list
  final VoidCallback onSaved;

  const QuestionEditorDialog(
      {super.key, this.question, required this.topics, required this.onSaved});

  @override
  State<QuestionEditorDialog> createState() => _QuestionEditorDialogState();
}

class _QuestionEditorDialogState extends State<QuestionEditorDialog>
    with SingleTickerProviderStateMixin {
  // Remember last-used Subject and Topic (Section) when adding successive questions
  static int? _rememberedSubjectId;
  static int? _rememberedTopicId;
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  final TranslationService _translationService = TranslationService();

  // Topic exclusion list for question editor (ECG is handled separately as a special case)
  static const List<String> _excludedTopicSlugs = ['ecg'];

  // English Controllers
  late TextEditingController _textControllerEn;
  late TextEditingController _explanationControllerEn;

  // Hungarian Controllers
  late TextEditingController _textControllerHu;
  late TextEditingController _explanationControllerHu;

  // Option Lists (Dynamic)
  List<String> _currentOptionsEn = ['', '', '', ''];
  List<String> _currentOptionsHu = ['', '', '', ''];

  // Image Upload
  XFile? _selectedImage;
  String? _existingImageUrl;

  // Loading States
  bool _isTranslating = false;

  // Relation Analysis fields
  late TextEditingController _s1EnController;
  late TextEditingController _s1HuController;
  late TextEditingController _s2EnController;
  late TextEditingController _s2HuController;
  late TextEditingController _linkEnController;
  late TextEditingController _linkHuController;

  // Matching fields (1-to-1)
  final List<MatchingPairControllerGroup> _matchingGroups = [];

  // Multiple Choice (Multi-select)
  final List<int> _multipleCorrectIndices = [];

  // Metadata Fields
  int? _selectedTopicId;
  int? _selectedSubjectId;
  int _bloomLevel = 1;
  String _questionType = 'single_choice';
  int? _correctIndex;
  late TextEditingController _tfStatementController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) setState(() {});
    });

    _textControllerEn =
        TextEditingController(text: widget.question?.text ?? '');
    _explanationControllerEn =
        TextEditingController(text: widget.question?.explanation ?? '');
    _textControllerHu =
        TextEditingController(text: widget.question?.questionTextHu ?? '');
    _explanationControllerHu =
        TextEditingController(text: widget.question?.explanationHu ?? '');

    _selectedTopicId = widget.question?.topicId;

    if (_selectedTopicId != null) {
      for (var t in widget.topics) {
        if (t['id'] == _selectedTopicId) {
          _selectedSubjectId = t['parent_id'];
          break;
        }
      }
    }

    // If creating a new question, restore last-used subject/topic for convenience
    if (widget.question == null) {
      if (_rememberedSubjectId != null && _selectedSubjectId == null) {
        _selectedSubjectId = _rememberedSubjectId;
      }
      if (_rememberedTopicId != null && _selectedTopicId == null) {
        // Ensure the remembered topic belongs to the selected subject
        final matches = widget.topics.where((t) =>
            t['id'] == _rememberedTopicId &&
            t['parent_id'] == _selectedSubjectId);
        if (matches.isNotEmpty) {
          _selectedTopicId = _rememberedTopicId;
        }
      }
    }

    _bloomLevel = widget.question?.bloomLevel ?? 1;
    _questionType = widget.question?.type ?? 'single_choice';

    _s1EnController = TextEditingController();
    _s1HuController = TextEditingController();
    _s2EnController = TextEditingController();
    _s2HuController = TextEditingController();
    _linkEnController = TextEditingController(text: 'because');
    _linkHuController = TextEditingController(text: 'mert');
    _tfStatementController = TextEditingController();

    _loadTypeSpecificData();
    _initOptions();

    _textControllerEn.addListener(() => setState(() {}));
    _textControllerHu.addListener(() => setState(() {}));
    _explanationControllerEn.addListener(() => setState(() {}));
    _explanationControllerHu.addListener(() => setState(() {}));
    _s1EnController.addListener(() => setState(() {}));
    _s1HuController.addListener(() => setState(() {}));
    _s2EnController.addListener(() => setState(() {}));
    _s2HuController.addListener(() => setState(() {}));
    _linkEnController.addListener(() => setState(() {}));
    _linkHuController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textControllerEn.dispose();
    _explanationControllerEn.dispose();
    _textControllerHu.dispose();
    _explanationControllerHu.dispose();
    _s1EnController.dispose();
    _s1HuController.dispose();
    _s2EnController.dispose();
    _s2HuController.dispose();
    _linkEnController.dispose();
    _linkHuController.dispose();
    _tfStatementController.dispose();
    for (var g in _matchingGroups) {
      g.dispose();
    }
    super.dispose();
  }

  void _initOptions() {
    if (widget.question?.content != null && widget.question!.content is Map) {
      _existingImageUrl = widget.question!.content['image_url'];
    }

    List<String> optsEn = [];
    if (widget.question != null) {
      dynamic rawOptions = widget.question!.options;
      if (rawOptions is String) {
        try {
          final decoded = json.decode(rawOptions);
          if (decoded is List) {
            optsEn = (decoded).map((e) => e?.toString() ?? '').toList();
          } else if (decoded is Map && decoded.containsKey('en')) {
            optsEn = (decoded['en'] as List)
                .map((e) => e?.toString() ?? '')
                .toList();
          }
        } catch (_) {}
      } else if (rawOptions is List) {
        optsEn = (rawOptions).map((e) => e?.toString() ?? '').toList();
      } else if (rawOptions is Map && rawOptions.containsKey('en')) {
        optsEn =
            (rawOptions['en'] as List).map((e) => e?.toString() ?? '').toList();
      }
    }
    if (optsEn.isEmpty) optsEn = ['', '', '', ''];
    _currentOptionsEn = optsEn;

    List<String> optsHu = [];
    if (widget.question?.optionsHu != null) {
      optsHu = widget.question!.optionsHu!;
    } else {
      optsHu = List.filled(_currentOptionsEn.length, '');
    }

    while (optsHu.length < _currentOptionsEn.length) {
      optsHu.add('');
    }
    _currentOptionsHu = optsHu;

    if (_questionType == 'single_choice' && widget.question != null) {
      _correctIndex = _currentOptionsEn
          .indexWhere((o) => o == widget.question!.correctAnswer);
      if (_correctIndex == -1) _correctIndex = 0;
    } else {
      _correctIndex = 0;
    }
  }

  void _loadTypeSpecificData() {
    if (widget.question == null) return;
    final content = widget.question!.content;
    if (content == null || content is! Map) return;

    if (_questionType == 'relation_analysis') {
      _s1EnController.text = content['statement1']?['en'] ?? '';
      _s1HuController.text = content['statement1']?['hu'] ?? '';
      _s2EnController.text = content['statement2']?['en'] ?? '';
      _s2HuController.text = content['statement2']?['hu'] ?? '';
      _linkEnController.text = content['link_word']?['en'] ?? 'because';
      _linkHuController.text = content['link_word']?['hu'] ?? 'mert';

      final corr = widget.question!.correctAnswer;
      if (corr is String) {
        final idx = corr.toUpperCase().codeUnitAt(0) - 'A'.codeUnitAt(0);
        if (idx >= 0 && idx < 5) _correctIndex = idx;
      }
    } else if (_questionType == 'true_false') {
      _textControllerEn.text = content['statement']?['en'] ?? '';
      _textControllerHu.text = content['statement']?['hu'] ?? '';
      final corr = widget.question!.correctAnswer.toString().toLowerCase();
      _correctIndex = (corr == 'true') ? 0 : 1;
    } else if (_questionType == 'matching') {
      final List<dynamic>? pairs = content['pairs'];
      if (pairs != null) {
        for (var p in pairs) {
          _addMatchingGroup(
            leftE: p['left']?['en'] ?? '',
            leftH: p['left']?['hu'] ?? '',
            rightE: p['right']?['en'] ?? '',
            rightH: p['right']?['hu'] ?? '',
          );
        }
      }
    } else if (_questionType == 'multiple_choice') {
      final corr = widget.question!.correctAnswer;
      if (corr is List) {
        for (var val in corr) {
          final idx = _currentOptionsEn.indexOf(val.toString());
          if (idx != -1) _multipleCorrectIndices.add(idx);
        }
      }
    }
  }

  AdminQuestion _getLiveQuestion() {
    return AdminQuestion(
        id: widget.question?.id ?? 0,
        text: _textControllerEn.text,
        questionTextHu: _textControllerHu.text,
        options: {
          'en': _currentOptionsEn,
          'hu': _currentOptionsHu,
        },
        correctAnswer: _correctIndex,
        explanation: _explanationControllerEn.text,
        explanationHu: _explanationControllerHu.text,
        topicId: _selectedTopicId ?? 0,
        bloomLevel: _bloomLevel,
        type: _questionType,
        content: {
          'image_url': _existingImageUrl,
          'statement1': {
            'en': _s1EnController.text,
            'hu': _s1HuController.text
          },
          'statement2': {
            'en': _s2EnController.text,
            'hu': _s2HuController.text
          },
          'link_word': {
            'en': _linkEnController.text,
            'hu': _linkHuController.text
          },
          'pairs': _matchingGroups
              .map((g) => {
                    'left': {'en': g.leftEn.text, 'hu': g.leftHu.text},
                    'right': {'en': g.rightEn.text, 'hu': g.rightHu.text},
                  })
              .toList(),
        });
  }

  void _addMatchingGroup(
      {String leftE = '',
      String leftH = '',
      String rightE = '',
      String rightH = ''}) {
    final group = MatchingPairControllerGroup(
      leftEn: TextEditingController(text: leftE),
      leftHu: TextEditingController(text: leftH),
      rightEn: TextEditingController(text: rightE),
      rightHu: TextEditingController(text: rightH),
    );
    group.leftEn.addListener(() => setState(() {}));
    group.leftHu.addListener(() => setState(() {}));
    group.rightEn.addListener(() => setState(() {}));
    group.rightHu.addListener(() => setState(() {}));
    setState(() {
      _matchingGroups.add(group);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return AlertDialog(
      title: Text(widget.question == null
          ? "Add Question"
          : "Edit Question #${widget.question!.id}"),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: 650,
        child: isMobile
            ? Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildMetadataSection(),
                    const SizedBox(height: 16),
                    const Divider(),
                    _buildTabBar(),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildLanguagePanel('en'),
                          _buildLanguagePanel('hu'),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildMetadataSection(),
                          const SizedBox(height: 16),
                          const Divider(),
                          _buildTabBar(),
                          const SizedBox(height: 16),
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                _buildLanguagePanel('en'),
                                _buildLanguagePanel('hu'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 32),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          const Text("LIVE PREVIEW",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                  fontSize: 10,
                                  letterSpacing: 1.2)),
                          const SizedBox(height: 16),
                          Expanded(
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: AdminPhonePreview(
                                  child: QuestionPreviewCard(
                                    question: _getLiveQuestion(),
                                    language:
                                        _tabController.index == 0 ? 'en' : 'hu',
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Showing ${_tabController.index == 0 ? 'English' : 'Hungarian'} version",
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel")),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
              backgroundColor: CozyTheme.of(context, listen: false).primary,
              foregroundColor: Colors.white),
          child: const Text("Save Question"),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: CozyTheme.of(context).primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: TabBar(
                controller: _tabController,
                labelColor: CozyTheme.of(context).primary,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: CozyTheme.of(context).paperWhite,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                dividerColor: Colors.transparent,
                labelStyle: GoogleFonts.quicksand(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(child: Text("English")),
                  Tab(child: Text("Hungarian")),
                ],
              ),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: _isTranslating
                  ? null
                  : () {
                      if (_tabController.index == 0) {
                        _translateAll('hu', 'en');
                      } else {
                        _translateAll('en', 'hu');
                      }
                    },
              icon: _isTranslating
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome,
                      size: 16, color: Colors.white),
              label: const Text("Auto Fill",
                  style: TextStyle(color: Colors.white)),
              style: TextButton.styleFrom(
                backgroundColor: CozyTheme.of(context, listen: false).primary,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataSection() {
    final subjects = widget.topics
        .where((t) =>
            t['parent_id'] == null && !_excludedTopicSlugs.contains(t['slug']))
        .toList();
    List<dynamic> sections = [];
    if (_selectedSubjectId != null) {
      sections = widget.topics
          .where((t) => t['parent_id'] == _selectedSubjectId)
          .toList();
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: DropdownButtonFormField<String>(
                key: ValueKey('type_$_questionType'),
                initialValue: _questionType,
                isExpanded: true,
                decoration: CozyTheme.inputDecoration(context, "Question Type")
                    .copyWith(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'single_choice',
                      child: Text('Single Choice',
                          overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(
                      value: 'multiple_choice',
                      child: Text('Multiple Choice',
                          overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(
                      value: 'true_false',
                      child:
                          Text('True/False', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(
                      value: 'relation_analysis',
                      child: Text('Relation Analysis',
                          overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(
                      value: 'matching',
                      child: Text('Matching', overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _questionType = val;
                      _onTypeChanged();
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<int>(
                key: ValueKey('bloom_$_bloomLevel'),
                initialValue: _bloomLevel,
                isExpanded: true,
                decoration: CozyTheme.inputDecoration(context, "Bloom Criteria")
                    .copyWith(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: [1, 2, 3, 4]
                    .map((l) => DropdownMenuItem(
                        value: l,
                        child:
                            Text("Level $l", overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (val) => setState(() => _bloomLevel = val!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int>(
                key: ValueKey('sub_$_selectedSubjectId'),
                initialValue: _selectedSubjectId,
                isExpanded: true,
                decoration:
                    CozyTheme.inputDecoration(context, "Subject").copyWith(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: subjects.map<DropdownMenuItem<int>>((s) {
                  return DropdownMenuItem(
                    value: s['id'] as int,
                    child: Text(
                        s['name']?.toString() ??
                            s['name_en']?.toString() ??
                            'Unnamed Subject',
                        overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                validator: (val) =>
                    val == null ? "Please select a Subject" : null,
                onChanged: (val) {
                  setState(() {
                    _selectedSubjectId = val;
                    _selectedTopicId = null;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                key: ValueKey('topic_$_selectedTopicId'),
                initialValue: _selectedTopicId,
                isExpanded: true,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                decoration:
                    CozyTheme.inputDecoration(context, "Section").copyWith(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                validator: (val) {
                  if (_selectedSubjectId != null && val == null) {
                    return "Please select a Section";
                  }
                  return null;
                },
                items: sections.isEmpty
                    ? []
                    : sections.map<DropdownMenuItem<int>>((s) {
                        return DropdownMenuItem(
                          value: s['id'] as int,
                          child: Text(
                              s['name']?.toString() ??
                                  s['name_en']?.toString() ??
                                  'Unnamed Topic',
                              overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                onChanged: sections.isEmpty
                    ? null
                    : (val) => setState(() => _selectedTopicId = val),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _onTypeChanged() {
    if (_questionType == 'relation_analysis') {
      _currentOptionsEn = ["A", "B", "C", "D", "E"];
      _currentOptionsHu = ["A", "B", "C", "D", "E"];
      _correctIndex = 0;
      if (_s1EnController.text.isEmpty) {
        _linkEnController.text = 'because';
        _linkHuController.text = 'mert';
      }
    } else if (_questionType == 'true_false') {
      _currentOptionsEn = ["True", "False"];
      _currentOptionsHu = ["Igaz", "Hamis"];
      _correctIndex = 0;
    } else if (_questionType == 'matching') {
      if (_matchingGroups.isEmpty) {
        _matchingGroups.add(MatchingPairControllerGroup(
            leftEn: TextEditingController(),
            leftHu: TextEditingController(),
            rightEn: TextEditingController(),
            rightHu: TextEditingController()));
      }
    } else if (_questionType == 'multiple_choice') {
      if (_currentOptionsEn.length < 2) {
        _currentOptionsEn = ["", "", "", ""];
        _currentOptionsHu = ["", "", "", ""];
      }
    } else {
      if (_currentOptionsEn.length < 2) {
        _currentOptionsEn = ["", "", "", ""];
        _currentOptionsHu = ["", "", "", ""];
      }
    }
  }

  Future<void> _translateAll(String source, String target) async {
    setState(() => _isTranslating = true);
    try {
      final Map<String, dynamic> srcData = {
        'explanation': source == 'en'
            ? _explanationControllerEn.text
            : _explanationControllerHu.text,
      };

      if (_questionType == 'relation_analysis') {
        srcData['statement1'] =
            source == 'en' ? _s1EnController.text : _s1HuController.text;
        srcData['statement2'] =
            source == 'en' ? _s2EnController.text : _s2HuController.text;
        srcData['link_word'] =
            source == 'en' ? _linkEnController.text : _linkHuController.text;
      } else if (_questionType == 'matching') {
        srcData['lefts'] = _matchingGroups
            .map((MatchingPairControllerGroup g) =>
                source == 'en' ? g.leftEn.text : g.leftHu.text)
            .toList();
        srcData['rights'] = _matchingGroups
            .map((MatchingPairControllerGroup g) =>
                source == 'en' ? g.rightEn.text : g.rightHu.text)
            .toList();
      } else {
        srcData['questionText'] =
            source == 'en' ? _textControllerEn.text : _textControllerHu.text;
        srcData['options'] =
            source == 'en' ? _currentOptionsEn : _currentOptionsHu;
      }

      final result = await _translationService.translateQuestion(
        questionData: srcData,
        from: source,
        to: target,
      );

      if (result != null) {
        String stripPrefix(String? text) {
          if (text == null) return "";
          return text
              .replaceAll('[HU] ', '')
              .replaceAll('[HU]', '')
              .replaceAll('[EN] ', '')
              .replaceAll('[EN]', '');
        }

        setState(() {
          if (target == 'hu') {
            if (result['explanation'] != null) {
              _explanationControllerHu.text =
                  stripPrefix(result['explanation']);
            }
            if (_questionType == 'relation_analysis') {
              if (result['statement1'] != null) {
                _s1HuController.text = stripPrefix(result['statement1']);
              }
              if (result['statement2'] != null) {
                _s2HuController.text = stripPrefix(result['statement2']);
              }
              if (result['link_word'] != null) {
                _linkHuController.text = stripPrefix(result['link_word']);
              }
            } else if (_questionType == 'matching') {
              if (result['lefts'] != null) {
                final list = result['lefts'] as List;
                for (int i = 0;
                    i < list.length && i < _matchingGroups.length;
                    i++) {
                  _matchingGroups[i].leftHu.text =
                      stripPrefix(list[i].toString());
                }
              }
              if (result['rights'] != null) {
                final list = result['rights'] as List;
                for (int i = 0;
                    i < list.length && i < _matchingGroups.length;
                    i++) {
                  _matchingGroups[i].rightHu.text =
                      stripPrefix(list[i].toString());
                }
              }
            } else {
              if (result['questionText'] != null) {
                _textControllerHu.text = stripPrefix(result['questionText']);
              }
              if (result['options'] != null) {
                _currentOptionsHu = (result['options'] as List)
                    .map((e) => stripPrefix(e.toString()))
                    .toList();
              }
            }
          } else {
            if (result['explanation'] != null) {
              _explanationControllerEn.text =
                  stripPrefix(result['explanation']);
            }
            if (_questionType == 'relation_analysis') {
              if (result['statement1'] != null) {
                _s1EnController.text = stripPrefix(result['statement1']);
              }
              if (result['statement2'] != null) {
                _s2EnController.text = stripPrefix(result['statement2']);
              }
              if (result['link_word'] != null) {
                _linkEnController.text = stripPrefix(result['link_word']);
              }
            } else if (_questionType == 'matching') {
              if (result['lefts'] != null) {
                final list = result['lefts'] as List;
                for (int i = 0;
                    i < list.length && i < _matchingGroups.length;
                    i++) {
                  _matchingGroups[i].leftEn.text =
                      stripPrefix(list[i].toString());
                }
              }
              if (result['rights'] != null) {
                final list = result['rights'] as List;
                for (int i = 0;
                    i < list.length && i < _matchingGroups.length;
                    i++) {
                  _matchingGroups[i].rightEn.text =
                      stripPrefix(list[i].toString());
                }
              }
            } else {
              if (result['questionText'] != null) {
                _textControllerEn.text = stripPrefix(result['questionText']);
              }
              if (result['options'] != null) {
                _currentOptionsEn = (result['options'] as List)
                    .map((e) => stripPrefix(e.toString()))
                    .toList();
              }
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Translation failed: $e")));
      }
    } finally {
      if (mounted) setState(() => _isTranslating = false);
    }
  }

  Widget _buildLanguagePanel(String lang) {
    final isEn = lang == 'en';
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_questionType != 'matching') ...[
            DualLanguageField(
              controllerEn: _textControllerEn,
              controllerHu: _textControllerHu,
              label: "Question Text",
              currentLanguage: lang,
              isMultiLine: true,
              isTranslating: _isTranslating,
              onTranslate: () => _translateField(
                from: isEn ? 'hu' : 'en',
                to: lang,
                sourceCtrl: isEn ? _textControllerHu : _textControllerEn,
                targetCtrl: isEn ? _textControllerEn : _textControllerHu,
              ),
            ),
            const SizedBox(height: 16),
          ],
          _buildTypeSpecificEditor(lang),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          DualLanguageField(
            controllerEn: _explanationControllerEn,
            controllerHu: _explanationControllerHu,
            label: "Explanation",
            currentLanguage: lang,
            isMultiLine: true,
            isTranslating: _isTranslating,
            onTranslate: () => _translateField(
              from: isEn ? 'hu' : 'en',
              to: lang,
              sourceCtrl:
                  isEn ? _explanationControllerHu : _explanationControllerEn,
              targetCtrl:
                  isEn ? _explanationControllerEn : _explanationControllerHu,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTypeSpecificEditor(String lang) {
    switch (_questionType) {
      case 'relation_analysis':
        return _buildRelationAnalysisEditor(lang);
      case 'matching':
        return _buildMatchingEditor(lang);
      case 'multiple_choice':
        return _buildMultipleChoiceEditor(lang);
      case 'true_false':
        return _buildTrueFalseEditor(lang);
      default:
        return _buildSingleChoiceEditor(lang);
    }
  }

  Widget _buildSingleChoiceEditor(String lang) {
    final isEn = lang == 'en';
    return DynamicOptionList(
      options: isEn ? _currentOptionsEn : _currentOptionsHu,
      correctIndex: _correctIndex ?? 0,
      onOptionsChanged: (newOpts) => setState(() =>
          isEn ? _currentOptionsEn = newOpts : _currentOptionsHu = newOpts),
      onCorrectIndexChanged: (idx) => setState(() => _correctIndex = idx),
      onAdd: () => setState(() {
        _currentOptionsEn.add("");
        _currentOptionsHu.add("");
      }),
      onRemove: (idx) {
        if (_currentOptionsEn.length <= 2) return;
        setState(() {
          _currentOptionsEn.removeAt(idx);
          _currentOptionsHu.removeAt(idx);
          if (_correctIndex == idx) {
            _correctIndex = 0;
          } else if (_correctIndex != null && _correctIndex! > idx) {
            _correctIndex = _correctIndex! - 1;
          }
        });
      },
    );
  }

  Widget _buildMultipleChoiceEditor(String lang) {
    final isEn = lang == 'en';
    final currentOpts = isEn ? _currentOptionsEn : _currentOptionsHu;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Options (Select all correct ones)",
            style: GoogleFonts.quicksand(
                fontWeight: FontWeight.bold, color: Colors.grey[700])),
        const SizedBox(height: 8),
        ...List.generate(currentOpts.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Checkbox(
                  value: _multipleCorrectIndices.contains(index),
                  onChanged: (val) => setState(() => val == true
                      ? _multipleCorrectIndices.add(index)
                      : _multipleCorrectIndices.remove(index)),
                ),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: currentOpts[index])
                      ..selection = TextSelection.fromPosition(
                          TextPosition(offset: currentOpts[index].length)),
                    onChanged: (val) => setState(() => isEn
                        ? _currentOptionsEn[index] = val
                        : _currentOptionsHu[index] = val),
                    decoration: InputDecoration(
                        labelText: "Option ${index + 1}",
                        border: const OutlineInputBorder(),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      color: Colors.red),
                  onPressed: () {
                    if (currentOpts.length <= 2) return;
                    setState(() {
                      _currentOptionsEn.removeAt(index);
                      _currentOptionsHu.removeAt(index);
                      _multipleCorrectIndices.remove(index);
                      for (int i = 0; i < _multipleCorrectIndices.length; i++) {
                        if (_multipleCorrectIndices[i] > index) {
                          _multipleCorrectIndices[i]--;
                        }
                      }
                    });
                  },
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
            onPressed: () => setState(() {
                  _currentOptionsEn.add("");
                  _currentOptionsHu.add("");
                }),
            icon: const Icon(Icons.add),
            label: const Text("Add Option")),
      ],
    );
  }

  Widget _buildRelationAnalysisEditor(String lang) {
    bool s1 = false;
    bool s2 = false;
    bool link = false;
    int idx = _correctIndex ?? 0;
    if ([0, 1, 2].contains(idx)) s1 = true;
    if ([0, 1, 3].contains(idx)) s2 = true;
    if (idx == 0) link = true;
    int calculateIndex(bool s1, bool s2, bool link) {
      if (s1 && s2) return link ? 0 : 1;
      if (s1 && !s2) return 2;
      if (!s1 && s2) return 3;
      return 4;
    }

    return Column(
      children: [
        const Text("Set Correct Logic",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 16),
        _buildRAOption(!s1, s1, "Statement 1 is TRUE",
            (val) => _correctIndex = calculateIndex(val, s2, link)),
        const SizedBox(height: 12),
        _buildRAOption(!s2, s2, "Statement 2 is TRUE",
            (val) => _correctIndex = calculateIndex(s1, val, link)),
        const SizedBox(height: 12),
        Opacity(
          opacity: (s1 && s2) ? 1.0 : 0.5,
          child: _buildRAOption(
              !link, link, "Connection / Link Exists (Because...)", (val) {
            if (s1 && s2) _correctIndex = calculateIndex(s1, s2, val);
          }, isLink: true),
        ),
      ],
    );
  }

  Widget _buildRAOption(
      bool toggle, bool active, String label, Function(bool) onChanged,
      {bool isLink = false}) {
    return InkWell(
      onTap: () => setState(() => onChanged(!active)),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
              color: active
                  ? CozyTheme.of(context).primary
                  : CozyTheme.of(context).textSecondary.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
          color: active
              ? CozyTheme.of(context).primary.withValues(alpha: 0.05)
              : Colors.transparent,
        ),
        child: Row(children: [
          Icon(
              isLink
                  ? (active ? Icons.link : Icons.link_off)
                  : (active ? Icons.check_box : Icons.check_box_outline_blank),
              color: active
                  ? (isLink
                      ? CozyTheme.of(context).secondary
                      : CozyTheme.of(context).primary)
                  : CozyTheme.of(context).textSecondary),
          const SizedBox(width: 12),
          Text(label),
        ]),
      ),
    );
  }

  Widget _buildTrueFalseEditor(String lang) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChoiceChip(
          label: const Text("TRUE"),
          labelStyle: TextStyle(
              color: _correctIndex == 0
                  ? CozyTheme.of(context).textInverse
                  : CozyTheme.of(context).primary,
              fontWeight: FontWeight.bold),
          selected: _correctIndex == 0,
          selectedColor: CozyTheme.of(context).primary,
          backgroundColor: CozyTheme.of(context).paperWhite,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: CozyTheme.of(context).primary)),
          onSelected: (val) => setState(() => _correctIndex = 0),
        ),
        const SizedBox(width: 24),
        ChoiceChip(
          label: const Text("FALSE"),
          labelStyle: TextStyle(
              color: _correctIndex == 1
                  ? CozyTheme.of(context).textInverse
                  : CozyTheme.of(context).accent,
              fontWeight: FontWeight.bold),
          selected: _correctIndex == 1,
          selectedColor: CozyTheme.of(context).accent,
          backgroundColor: CozyTheme.of(context).paperWhite,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: CozyTheme.of(context).accent)),
          onSelected: (val) => setState(() => _correctIndex = 1),
        ),
      ],
    );
  }

  Widget _buildMatchingEditor(String lang) {
    final isEn = lang == 'en';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("1-to-1 Matching Pairs",
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._matchingGroups.asMap().entries.map((entry) {
          final idx = entry.key;
          final group = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                Expanded(
                    child: TextField(
                        controller: isEn ? group.leftEn : group.leftHu,
                        decoration: CozyTheme.inputDecoration(
                            context, "Left ${idx + 1}"))),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child:
                        Icon(Icons.link, color: CozyTheme.of(context).primary)),
                Expanded(
                    child: TextField(
                        controller: isEn ? group.rightEn : group.rightHu,
                        decoration: CozyTheme.inputDecoration(
                            context, "Right ${idx + 1}"))),
                IconButton(
                  icon: Icon(Icons.close, color: CozyTheme.of(context).error),
                  onPressed: () =>
                      setState(() => _matchingGroups.removeAt(idx)),
                ),
              ],
            ),
          );
        }),
        TextButton.icon(
            onPressed: () => _addMatchingGroup(),
            icon: const Icon(Icons.add),
            label: const Text("Add Pair")),
      ],
    );
  }

  Future<void> _translateField(
      {required String from,
      required String to,
      required TextEditingController sourceCtrl,
      required TextEditingController targetCtrl}) async {
    if (sourceCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Source field is empty!")),
      );
      return;
    }
    setState(() => _isTranslating = true);
    try {
      final translated =
          await _translationService.translateText(sourceCtrl.text, from, to);
      if (translated != null) {
        setState(() => targetCtrl.text = translated);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Translation failed")));
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isTranslating = false);
      }
    }
  }

  void _save() async {
    final stats = Provider.of<StatsProvider>(context, listen: false);
    if (!_formKey.currentState!.validate()) return;
    Map<String, dynamic> contentPayload = {'image_url': _existingImageUrl};
    dynamic correctAnswerPayload;
    if (_questionType == 'relation_analysis') {
      contentPayload['statement1'] = {
        'en': _s1EnController.text,
        'hu': _s1HuController.text
      };
      contentPayload['statement2'] = {
        'en': _s2EnController.text,
        'hu': _s2HuController.text
      };
      contentPayload['link_word'] = {
        'en': _linkEnController.text,
        'hu': _linkHuController.text
      };
      correctAnswerPayload =
          String.fromCharCode('A'.codeUnitAt(0) + (_correctIndex ?? 0));
    } else if (_questionType == 'matching') {
      final List<Map<String, dynamic>> pairs = [];
      final Map<String, String> correctMap = {};
      for (var group in _matchingGroups) {
        pairs.add({
          'left': {'en': group.leftEn.text, 'hu': group.leftHu.text},
          'right': {'en': group.rightEn.text, 'hu': group.rightHu.text}
        });
        if (group.leftEn.text.isNotEmpty) {
          correctMap[group.leftEn.text] = group.rightEn.text;
        }
      }
      contentPayload['pairs'] = pairs;
      correctAnswerPayload = correctMap;
    } else if (_questionType == 'multiple_choice') {
      correctAnswerPayload =
          _multipleCorrectIndices.map((idx) => _currentOptionsEn[idx]).toList();
      contentPayload['is_multi'] = true;
    } else if (_questionType == 'true_false') {
      contentPayload['statement'] = {
        'en': _textControllerEn.text,
        'hu': _textControllerHu.text
      };
      correctAnswerPayload = (_correctIndex == 0) ? 'true' : 'false';
    } else {
      correctAnswerPayload = _currentOptionsEn[_correctIndex ?? 0];
    }

    final payload = {
      'question_text_en': _textControllerEn.text,
      'question_text_hu': _textControllerHu.text,
      'options_en': _currentOptionsEn,
      'options_hu': _currentOptionsHu,
      'explanation_en': _explanationControllerEn.text,
      'explanation_hu': _explanationControllerHu.text,
      'correct_answer': correctAnswerPayload,
      'question_type': _questionType,
      'topic_id': _selectedTopicId,
      'bloom_level': _bloomLevel,
      'content': contentPayload,
    };
    if (_selectedImage != null) {
      final url = await ApiService().uploadImage(_selectedImage!);
      if (url != null) {
        (payload['content'] as Map)['image_url'] = url;
      }
    }
    final success = (widget.question == null)
        ? await stats.createQuestion(payload)
        : await stats.updateQuestion(widget.question!.id, payload);

    if (!mounted) return;

    if (success) {
      // Remember last used subject and topic when creating a new question
      if (widget.question == null) {
        _QuestionEditorDialogState._rememberedSubjectId = _selectedSubjectId;
        _QuestionEditorDialogState._rememberedTopicId = _selectedTopicId;
      }
      Navigator.pop(context);
      widget.onSaved();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to save question")),
      );
    }
  }
}

class MatchingPairControllerGroup {
  final TextEditingController leftEn;
  final TextEditingController leftHu;
  final TextEditingController rightEn;
  final TextEditingController rightHu;

  MatchingPairControllerGroup({
    required this.leftEn,
    required this.leftHu,
    required this.rightEn,
    required this.rightHu,
  });

  void dispose() {
    leftEn.dispose();
    leftHu.dispose();
    rightEn.dispose();
    rightHu.dispose();
  }
}
