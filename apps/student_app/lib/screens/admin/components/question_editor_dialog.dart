import 'package:arbor_med/core/models/topic_hierarchy.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:arbor_med/core/models/admin_question.dart';
import '../../../services/admin_question_provider.dart';
import '../../../services/api_service.dart';
import '../../../theme/cozy_theme.dart';
import 'dart:convert';
import '../../../widgets/admin/dual_language_field.dart';

import '../../../services/translation_service.dart';
import 'question_preview_card.dart';
import 'admin_phone_preview.dart';
import 'matching_pair_controller_group.dart';
import 'quiz_forms/true_false_editor.dart';
import 'quiz_forms/relation_analysis_editor.dart';
import 'quiz_forms/multiple_choice_editor.dart';
import 'quiz_forms/single_choice_editor.dart';
import 'question_translation_helper.dart';
import 'quiz_forms/matching_editor.dart';
import 'question_metadata_section.dart';
import 'question_editor_tab_bar.dart';
import 'question_payload_builder.dart';
import '../../../generated/l10n/app_localizations.dart';

class QuestionEditorDialog extends StatefulWidget {
  final AdminQuestion? question;
  final List<Map<String, dynamic>> topics;
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

  List<AdminChoice?> _originalChoices = [];

  // Image Upload
  PlatformFile? _selectedImage;
  bool _isSaving = false;
  bool _isPickingImage = false;
  String? _formError;
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
  late TopicHierarchy _hierarchy;
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

    _hierarchy = TopicHierarchy(widget.topics);
    _selectedSubjectId = _hierarchy.subjectOf[_selectedTopicId];
    if (_selectedSubjectId == null) _selectedTopicId = null;

    // If creating a new question, restore last-used subject/topic for convenience
    if (widget.question == null) {
      if (_rememberedSubjectId != null && _hierarchy.subjectOf[_rememberedSubjectId] == _rememberedSubjectId) {
        _selectedSubjectId = _rememberedSubjectId;
      }
      if (_rememberedTopicId != null && _selectedTopicId == null) {
        // Ensure the remembered topic belongs to the selected subject
        if (_selectedSubjectId != null && _hierarchy.subjectOf[_rememberedTopicId] == _selectedSubjectId) {
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

    _initOptions();
    _loadTypeSpecificData();

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

    final question = widget.question;
    final choices = question?.choices ?? const <AdminChoice>[];
    if (choices.isNotEmpty) {
      _currentOptionsEn = choices.map((choice) => choice.en).toList();
      _currentOptionsHu = choices.map((choice) => choice.hu).toList();
    }
    _originalChoices = List<AdminChoice?>.of(choices);
    if (_questionType == 'single_choice') {
      final keys = question?.answerKeys;
      _correctIndex = keys?.length == 1 ? question!.choiceIndex(keys!.single) : null;
    } else {
      _correctIndex = 0;
    }
  }

  @override
  void didUpdateWidget(QuestionEditorDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.topics, widget.topics)) return;
    _hierarchy = TopicHierarchy(widget.topics);
    if (!_hierarchy.roots.contains(_selectedSubjectId)) {
      _selectedSubjectId = null;
    }
    if (_hierarchy.subjectOf[_selectedTopicId] != _selectedSubjectId ||
        _selectedSubjectId == null) {
      _selectedTopicId = null;
    }
  }

  void _loadTypeSpecificData() {
    QuestionPayloadBuilder.loadTypeSpecificData(
      question: widget.question,
      questionType: _questionType,
      s1EnController: _s1EnController,
      s1HuController: _s1HuController,
      s2EnController: _s2EnController,
      s2HuController: _s2HuController,
      linkEnController: _linkEnController,
      linkHuController: _linkHuController,
      textControllerEn: _textControllerEn,
      textControllerHu: _textControllerHu,
      setCorrectIndex: (idx) => _correctIndex = idx,
      addMultipleCorrectIndex: (idx) => _multipleCorrectIndices.add(idx),
      addMatchingGroup: _addMatchingGroup,
    );
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

    return PopScope(canPop: !_isSaving, child: AlertDialog(
      title: Text(widget.question == null
          ? AppLocalizations.of(context)!.adminAddQuestion
          : "${AppLocalizations.of(context)!.adminEditQuestion} #${widget.question!.id}"),
      content: ExcludeFocus(excluding: _isSaving, child: AbsorbPointer(absorbing: _isSaving, child: SizedBox(
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
                          Text(AppLocalizations.of(context)!.adminLivePreview,
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
                                    draftImage: _selectedImage?.bytes == null
                                        ? null : MemoryImage(_selectedImage!.bytes!),
                                    language:
                                        _tabController.index == 0 ? 'en' : 'hu',
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "${AppLocalizations.of(context)!.adminShowing} ${_tabController.index == 0 ? AppLocalizations.of(context)!.adminEnglish : AppLocalizations.of(context)!.adminHungarian} ${AppLocalizations.of(context)!.adminVersion}",
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ))),
      actions: [
        if (_formError != null) Semantics(container: true, liveRegion: true, child: Text(_formError!,
          style: TextStyle(color: Theme.of(context).colorScheme.error))),
        TextButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel)),
        ElevatedButton(
          onPressed: _isSaving || _isPickingImage || _isTranslating ? null : _save,
          style: ElevatedButton.styleFrom(
              backgroundColor: CozyTheme.of(context, listen: false).primary,
              foregroundColor: Colors.white),
          child: Text(AppLocalizations.of(context)!.adminSaveQuestion),
        ),
      ],
    ));
  }

  Widget _buildTabBar() {
    return QuestionEditorTabBar(
      controller: _tabController,
      isTranslating: _isTranslating,
      onAutoFill: () {
        if (_tabController.index == 0) {
          _translateAll('hu', 'en');
        } else {
          _translateAll('en', 'hu');
        }
      },
    );
  }
  Widget _buildMetadataSection() {
    return QuestionMetadataSection(
      hierarchy: _hierarchy,
      excludedTopicSlugs: _excludedTopicSlugs,
      questionType: _questionType,
      bloomLevel: _bloomLevel,
      selectedSubjectId: _selectedSubjectId,
      selectedTopicId: _selectedTopicId,
      onQuestionTypeChanged: (val) {
        setState(() {
          if (!const {'single_choice','multiple_choice'}.contains(val) ||
              !const {'single_choice','multiple_choice'}.contains(_questionType)) {
            _originalChoices.clear();
          }
          _questionType = val;
          _onTypeChanged();
        });
      },
      onBloomLevelChanged: (val) => setState(() => _bloomLevel = val),
      onSubjectChanged: (val) {
        setState(() {
          _selectedSubjectId = val;
          _selectedTopicId = null;
        });
      },
      onTopicChanged: (val) => setState(() => _selectedTopicId = val),
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
    } else if (_currentOptionsEn.length < 2) {
      _currentOptionsEn = ["", "", "", ""];
      _currentOptionsHu = ["", "", "", ""];
    }
    _multipleCorrectIndices.clear();
    if (_questionType == 'single_choice') _correctIndex = null;
  }

  Map<String, dynamic> _translationFields(String source) =>
      QuestionTranslationHelper.buildTranslationPayload(
        questionType: _questionType,
        source: source,
        explanation: source == 'en'
            ? _explanationControllerEn.text
            : _explanationControllerHu.text,
        questionText:
            source == 'en' ? _textControllerEn.text : _textControllerHu.text,
        options: source == 'en' ? _currentOptionsEn : _currentOptionsHu,
        s1: source == 'en' ? _s1EnController.text : _s1HuController.text,
        s2: source == 'en' ? _s2EnController.text : _s2HuController.text,
        linkWord:
            source == 'en' ? _linkEnController.text : _linkHuController.text,
        matchingGroups: _matchingGroups,
      );

  void _translationNotice(String message) {
    setState(() => _formError = message);
  }

  Future<void> _translateAll(String source, String target) async {
    if (_isTranslating) return;
    final labels = AppLocalizations.of(context)!;
    final srcData = _translationFields(source);
    final hasText = srcData.values.expand((v) => v is List ? v : [v])
        .any((value) => value is String && value.trim().isNotEmpty);
    if (!hasText) {
      _translationNotice(labels.adminSourceFieldEmpty);
      return;
    }
    final type = _questionType;
    final originalTarget = jsonEncode(_translationFields(target));
    setState(() {
      _formError = null;
      _isTranslating = true;
    });
    try {
      final result = await _translationService.translateQuestion(
        questionData: srcData,
        from: source,
        to: target,
      );

      if (!mounted) return;
      if (result == null || !QuestionTranslationHelper.isComplete(srcData, result)) {
        _translationNotice(labels.translationFailed);
        return;
      }
      if (type != _questionType || jsonEncode(_translationFields(source)) != jsonEncode(srcData)
          || jsonEncode(_translationFields(target)) != originalTarget) {
        _translationNotice(labels.adminTranslationDraftChanged);
        return;
      }
      final isTargetHu = target == 'hu';
      final newOpts = QuestionTranslationHelper.applyTranslationResult(
        result: result,
        questionType: _questionType,
        isTargetHu: isTargetHu,
        explanationController: isTargetHu
            ? _explanationControllerHu
            : _explanationControllerEn,
        textController:
            isTargetHu ? _textControllerHu : _textControllerEn,
        s1Controller: isTargetHu ? _s1HuController : _s1EnController,
        s2Controller: isTargetHu ? _s2HuController : _s2EnController,
        linkController: isTargetHu ? _linkHuController : _linkEnController,
        matchingGroups: _matchingGroups,
        currentOptions: isTargetHu ? _currentOptionsHu : _currentOptionsEn,
      );

      if (newOpts != null) {
        setState(() {
          if (isTargetHu) {
            _currentOptionsHu = newOpts;
          } else {
            _currentOptionsEn = newOpts;
          }
        });
      }
    } catch (_) {
      if (mounted) _translationNotice(labels.translationFailed);
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
          if (_questionType == 'single_choice' || _questionType == 'multiple_choice') ...[
            Row(children: [
              OutlinedButton.icon(
                onPressed: _isPickingImage || _isSaving ? null : _pickIllustration,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(AppLocalizations.of(context)!.adminTableImage),
              ),
              if (_selectedImage != null || _existingImageUrl != null)
                IconButton(
                  tooltip: AppLocalizations.of(context)!.remove,
                  icon: const Icon(Icons.close),
                  onPressed: _isPickingImage || _isSaving ? null : () => setState(() {
                    _formError = null;
                    _selectedImage = null;
                    _existingImageUrl = null;
                  }),
                ),
            ]),
            if (_selectedImage?.bytes != null)
              Image.memory(_selectedImage!.bytes!, height: 100, fit: BoxFit.contain,
                errorBuilder: (_, error, stack) => const Icon(Icons.broken_image)),
            if (_selectedImage == null && _existingImageUrl != null)
              Image.network(Uri.parse(ApiService.baseUrl).resolve(_existingImageUrl!).toString(),
                height: 100, fit: BoxFit.contain,
                errorBuilder: (_, error, stack) => const Icon(Icons.broken_image)),
            const SizedBox(height: 12),
          ],
          if (_questionType != 'matching') ...[
            DualLanguageField(
              controllerEn: _textControllerEn,
              controllerHu: _textControllerHu,
              label: AppLocalizations.of(context)!.adminTableQuestionText,
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
          if (_questionType == 'relation_analysis')
            for (final entry in [
              (AppLocalizations.of(context)!.adminFirstStatement, _s1EnController, _s1HuController),
              (AppLocalizations.of(context)!.adminLinkWord, _linkEnController, _linkHuController),
              (AppLocalizations.of(context)!.adminSecondStatement, _s2EnController, _s2HuController),
            ])
              DualLanguageField(
                label: entry.$1, controllerEn: entry.$2, controllerHu: entry.$3,
                currentLanguage: lang, validator: (_) => null,
              ),
          _buildTypeSpecificEditor(lang),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          DualLanguageField(
            controllerEn: _explanationControllerEn,
            controllerHu: _explanationControllerHu,
            label: AppLocalizations.of(context)!.adminExplanationLabel,
            // Older and imported questions can already have an empty explanation.
            validator: widget.question != null &&
                    ((isEn ? widget.question!.explanation : widget.question!.explanationHu) ?? '').trim().isEmpty
                ? (_) => null
                : null,
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
        return RelationAnalysisEditor(
          correctIndex: _correctIndex,
          onIndexChanged: (idx) => setState(() => _correctIndex = idx),
        );
      case 'matching':
        return MatchingEditor(
          matchingGroups: _matchingGroups,
          isEn: lang == 'en',
          onAddPair: _addMatchingGroup,
          onRemovePair: (idx) => setState(() => _matchingGroups.removeAt(idx)),
        );
      case 'multiple_choice':
        final isEn = lang == 'en';
        return MultipleChoiceEditor(
          options: isEn ? _currentOptionsEn : _currentOptionsHu,
          correctIndices: _multipleCorrectIndices,
          onOptionChanged: (index, val) => setState(() {
            if (isEn) {
              _currentOptionsEn[index] = val;
            } else {
              _currentOptionsHu[index] = val;
            }
          }),
          onToggleCorrect: (index, isSelected) => setState(() {
            if (isSelected) {
              _multipleCorrectIndices.add(index);
            } else {
              _multipleCorrectIndices.remove(index);
            }
          }),
          onAddOption: () => setState(() {
            _currentOptionsEn = [..._currentOptionsEn, ""];
            _currentOptionsHu = [..._currentOptionsHu, ""];
          }),
          onRemoveOption: (index) => setState(() {
            if (index < _originalChoices.length) _originalChoices.removeAt(index);
            _currentOptionsEn = List.of(_currentOptionsEn)..removeAt(index);
            _currentOptionsHu = List.of(_currentOptionsHu)..removeAt(index);
            _multipleCorrectIndices.remove(index);
            for (int i = 0; i < _multipleCorrectIndices.length; i++) {
              if (_multipleCorrectIndices[i] > index) {
                _multipleCorrectIndices[i]--;
              }
            }
          }),
        );
      case 'true_false':
        return TrueFalseEditor(
          correctIndex: _correctIndex,
          onIndexChanged: (idx) => setState(() => _correctIndex = idx),
        );
      default:
        final isEn = lang == 'en';
        return SingleChoiceEditor(
          options: isEn ? _currentOptionsEn : _currentOptionsHu,
          correctIndex: _correctIndex,
          onOptionsChanged: (newOpts) => setState(() =>
              isEn ? _currentOptionsEn = newOpts : _currentOptionsHu = newOpts),
          onCorrectIndexChanged: (idx) => setState(() => _correctIndex = idx),
          onAdd: () => setState(() {
            _currentOptionsEn = [..._currentOptionsEn, ""];
            _currentOptionsHu = [..._currentOptionsHu, ""];
          }),
          onRemove: (idx) {
            if (_currentOptionsEn.length <= 2) return;
            setState(() {
              if (idx < _originalChoices.length) _originalChoices.removeAt(idx);
              _currentOptionsEn = List.of(_currentOptionsEn)..removeAt(idx);
              _currentOptionsHu = List.of(_currentOptionsHu)..removeAt(idx);
              if (_correctIndex == idx) {
                _correctIndex = null;
              } else if (_correctIndex != null && _correctIndex! > idx) {
                _correctIndex = _correctIndex! - 1;
              }
            });
          },
        );
    }
  }

  // Extracted relation analysis, true/false, matching, and multiple choice to external components

  Future<void> _translateField(
      {required String from,
      required String to,
      required TextEditingController sourceCtrl,
      required TextEditingController targetCtrl}) async {
    if (_isTranslating) return;
    final sourceText = sourceCtrl.text;
    final targetText = targetCtrl.text;
    final type = _questionType;
    if (sourceText.trim().isEmpty) {
      _translationNotice(AppLocalizations.of(context)!.adminSourceFieldEmpty);
      return;
    }
    setState(() {
      _formError = null;
      _isTranslating = true;
    });
    try {
      final translated =
          await _translationService.translateText(sourceText, from, to);
      if (!mounted) return;
      final labels = AppLocalizations.of(context)!;
      if (translated == null || translated.trim().isEmpty) {
        _translationNotice(labels.translationFailed);
      } else if (type != _questionType || sourceCtrl.text != sourceText || targetCtrl.text != targetText) {
        _translationNotice(labels.adminTranslationDraftChanged);
      } else {
        targetCtrl.text = translated;
      }
    } finally {
      if (mounted) {
        setState(() => _isTranslating = false);
      }
    }
  }

  Future<void> _pickIllustration() async {
    if (_isPickingImage || _isSaving) return;
    setState(() {
      _isPickingImage = true;
      _formError = null;
    });
    final labels = AppLocalizations.of(context)!;
    try {
      final files = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp'],
        withData: true,
      );
      if (!mounted || files == null || files.files.isEmpty) return;
      final file = files.files.single;
      if (file.bytes == null || file.size > ApiService.maxImageBytes) {
        setState(() => _formError = labels.adminEcgUploadFailed);
        return;
      }
      setState(() {
        _selectedImage = file;
        _existingImageUrl = null;
      });
    } catch (_) {
      if (mounted) setState(() => _formError = labels.adminEcgUploadFailed);
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  void _save() async {
    if (_isSaving || _isPickingImage || _isTranslating) return;
    final questionProvider =
        Provider.of<AdminQuestionProvider>(context, listen: false);
    if (!_formKey.currentState!.validate()) return;
    if ((_questionType == 'single_choice' && _correctIndex == null) ||
        (_questionType == 'multiple_choice' && _multipleCorrectIndices.isEmpty)) {
      final l = AppLocalizations.of(context)!;
      setState(() => _formError = '${l.correctAnswer} · ${l.adminRequired}');
      return;
    }
    if (_questionType == 'single_choice' || _questionType == 'multiple_choice') {
      for (var i = 0; i < _currentOptionsEn.length; i++) {
        if (_currentOptionsEn[i].trim().isEmpty && _currentOptionsHu[i].trim().isEmpty) {
          final l = AppLocalizations.of(context)!;
          setState(() => _formError = '${l.adminOptionIndex(i + 1)} · ${l.adminRequired}');
          return;
        }
      }
    }
    final payload = QuestionPayloadBuilder.buildPayload(
      questionType: _questionType,
      existingImageUrl: _existingImageUrl,
      correctIndex: _correctIndex,
      multipleCorrectIndices: _multipleCorrectIndices,
      originalChoices: _originalChoices,
      originalContent: widget.question?.type == _questionType && widget.question?.content is Map
          ? Map<String, dynamic>.from(widget.question!.content as Map)
          : const {},
      currentOptionsEn: _currentOptionsEn,
      currentOptionsHu: _currentOptionsHu,
      matchingGroups: _matchingGroups,
      textControllerEn: _textControllerEn,
      textControllerHu: _textControllerHu,
      explanationControllerEn: _explanationControllerEn,
      explanationControllerHu: _explanationControllerHu,
      s1EnController: _s1EnController,
      s1HuController: _s1HuController,
      s2EnController: _s2EnController,
      s2HuController: _s2HuController,
      linkEnController: _linkEnController,
      linkHuController: _linkHuController,
      selectedTopicId: _selectedTopicId,
      bloomLevel: _bloomLevel,
    );
    setState(() {
      _isSaving = true;
      _formError = null;
    });
    final selected = _selectedImage;
    if (selected != null) {
      final url = await questionProvider.apiService.uploadImageBytes(selected.bytes!, selected.name);
      if (!mounted) return;
      if (url == null) {
        setState(() {
          _isSaving = false;
          _formError = AppLocalizations.of(context)!.adminEcgUploadFailed;
        });
        return;
      }
      _selectedImage = null;
      _existingImageUrl = url;
      (payload['content'] as Map)['image_url'] = url;
    }
    final success = (widget.question == null)
        ? await questionProvider.createQuestion(payload)
        : await questionProvider.updateQuestion(widget.question!.id, payload);

    if (!mounted) return;

    setState(() => _isSaving = false);
    if (success) {
      // Remember last used subject and topic when creating a new question
      if (widget.question == null) {
        _QuestionEditorDialogState._rememberedSubjectId = _selectedSubjectId;
        _QuestionEditorDialogState._rememberedTopicId = _selectedTopicId;
      }
      Navigator.pop(context);
      widget.onSaved();
    } else {
      setState(() => _formError = AppLocalizations.of(context)!.adminErrorQuestionSaveFailed);
    }
  }
}

