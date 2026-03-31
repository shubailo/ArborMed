// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'topic_collection.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetTopicCollectionCollection on Isar {
  IsarCollection<TopicCollection> get topicCollections => this.collection();
}

const TopicCollectionSchema = CollectionSchema(
  name: r'TopicCollection',
  id: -2069587312509567965,
  properties: {
    r'createdAt': PropertySchema(
      id: 0,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'descriptionEn': PropertySchema(
      id: 1,
      name: r'descriptionEn',
      type: IsarType.string,
    ),
    r'descriptionHu': PropertySchema(
      id: 2,
      name: r'descriptionHu',
      type: IsarType.string,
    ),
    r'isPremium': PropertySchema(
      id: 3,
      name: r'isPremium',
      type: IsarType.bool,
    ),
    r'nameEn': PropertySchema(
      id: 4,
      name: r'nameEn',
      type: IsarType.string,
    ),
    r'nameHu': PropertySchema(
      id: 5,
      name: r'nameHu',
      type: IsarType.string,
    ),
    r'orderIndex': PropertySchema(
      id: 6,
      name: r'orderIndex',
      type: IsarType.long,
    ),
    r'slug': PropertySchema(
      id: 7,
      name: r'slug',
      type: IsarType.string,
    ),
    r'updatedAt': PropertySchema(
      id: 8,
      name: r'updatedAt',
      type: IsarType.dateTime,
    )
  },
  estimateSize: _topicCollectionEstimateSize,
  serialize: _topicCollectionSerialize,
  deserialize: _topicCollectionDeserialize,
  deserializeProp: _topicCollectionDeserializeProp,
  idName: r'id',
  indexes: {
    r'slug': IndexSchema(
      id: 6169444064746062836,
      name: r'slug',
      unique: true,
      replace: true,
      properties: [
        IndexPropertySchema(
          name: r'slug',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _topicCollectionGetId,
  getLinks: _topicCollectionGetLinks,
  attach: _topicCollectionAttach,
  version: '3.1.0+1',
);

int _topicCollectionEstimateSize(
  TopicCollection object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.descriptionEn;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.descriptionHu;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.nameEn.length * 3;
  bytesCount += 3 + object.nameHu.length * 3;
  bytesCount += 3 + object.slug.length * 3;
  return bytesCount;
}

void _topicCollectionSerialize(
  TopicCollection object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.createdAt);
  writer.writeString(offsets[1], object.descriptionEn);
  writer.writeString(offsets[2], object.descriptionHu);
  writer.writeBool(offsets[3], object.isPremium);
  writer.writeString(offsets[4], object.nameEn);
  writer.writeString(offsets[5], object.nameHu);
  writer.writeLong(offsets[6], object.orderIndex);
  writer.writeString(offsets[7], object.slug);
  writer.writeDateTime(offsets[8], object.updatedAt);
}

TopicCollection _topicCollectionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TopicCollection();
  object.createdAt = reader.readDateTime(offsets[0]);
  object.descriptionEn = reader.readStringOrNull(offsets[1]);
  object.descriptionHu = reader.readStringOrNull(offsets[2]);
  object.id = id;
  object.isPremium = reader.readBool(offsets[3]);
  object.nameEn = reader.readString(offsets[4]);
  object.nameHu = reader.readString(offsets[5]);
  object.orderIndex = reader.readLong(offsets[6]);
  object.slug = reader.readString(offsets[7]);
  object.updatedAt = reader.readDateTime(offsets[8]);
  return object;
}

P _topicCollectionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readStringOrNull(offset)) as P;
    case 3:
      return (reader.readBool(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readLong(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readDateTime(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _topicCollectionGetId(TopicCollection object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _topicCollectionGetLinks(TopicCollection object) {
  return [];
}

void _topicCollectionAttach(
    IsarCollection<dynamic> col, Id id, TopicCollection object) {
  object.id = id;
}

extension TopicCollectionByIndex on IsarCollection<TopicCollection> {
  Future<TopicCollection?> getBySlug(String slug) {
    return getByIndex(r'slug', [slug]);
  }

  TopicCollection? getBySlugSync(String slug) {
    return getByIndexSync(r'slug', [slug]);
  }

  Future<bool> deleteBySlug(String slug) {
    return deleteByIndex(r'slug', [slug]);
  }

  bool deleteBySlugSync(String slug) {
    return deleteByIndexSync(r'slug', [slug]);
  }

  Future<List<TopicCollection?>> getAllBySlug(List<String> slugValues) {
    final values = slugValues.map((e) => [e]).toList();
    return getAllByIndex(r'slug', values);
  }

  List<TopicCollection?> getAllBySlugSync(List<String> slugValues) {
    final values = slugValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'slug', values);
  }

  Future<int> deleteAllBySlug(List<String> slugValues) {
    final values = slugValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'slug', values);
  }

  int deleteAllBySlugSync(List<String> slugValues) {
    final values = slugValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'slug', values);
  }

  Future<Id> putBySlug(TopicCollection object) {
    return putByIndex(r'slug', object);
  }

  Id putBySlugSync(TopicCollection object, {bool saveLinks = true}) {
    return putByIndexSync(r'slug', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllBySlug(List<TopicCollection> objects) {
    return putAllByIndex(r'slug', objects);
  }

  List<Id> putAllBySlugSync(List<TopicCollection> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'slug', objects, saveLinks: saveLinks);
  }
}

extension TopicCollectionQueryWhereSort
    on QueryBuilder<TopicCollection, TopicCollection, QWhere> {
  QueryBuilder<TopicCollection, TopicCollection, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension TopicCollectionQueryWhere
    on QueryBuilder<TopicCollection, TopicCollection, QWhereClause> {
  QueryBuilder<TopicCollection, TopicCollection, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterWhereClause> slugEqualTo(
      String slug) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'slug',
        value: [slug],
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterWhereClause>
      slugNotEqualTo(String slug) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'slug',
              lower: [],
              upper: [slug],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'slug',
              lower: [slug],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'slug',
              lower: [slug],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'slug',
              lower: [],
              upper: [slug],
              includeUpper: false,
            ));
      }
    });
  }
}

extension TopicCollectionQueryFilter
    on QueryBuilder<TopicCollection, TopicCollection, QFilterCondition> {
  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      descriptionEnIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'descriptionEn',
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      descriptionEnIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'descriptionEn',
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      descriptionEnEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'descriptionEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      descriptionEnGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'descriptionEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      descriptionEnLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'descriptionEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      descriptionEnBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'descriptionEn',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      descriptionEnStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'descriptionEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      descriptionEnEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'descriptionEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      descriptionEnContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'descriptionEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      descriptionEnMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'descriptionEn',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      descriptionEnIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'descriptionEn',
        value: '',
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      descriptionEnIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'descriptionEn',
        value: '',
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      descriptionHuIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'descriptionHu',
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      descriptionHuIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'descriptionHu',
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      descriptionHuEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'descriptionHu',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      descriptionHuGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'descriptionHu',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      descriptionHuLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'descriptionHu',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      descriptionHuBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'descriptionHu',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      descriptionHuStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'descriptionHu',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      descriptionHuEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'descriptionHu',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      descriptionHuContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'descriptionHu',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      descriptionHuMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'descriptionHu',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      descriptionHuIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'descriptionHu',
        value: '',
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      descriptionHuIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'descriptionHu',
        value: '',
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      isPremiumEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isPremium',
        value: value,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      nameEnEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nameEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      nameEnGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nameEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      nameEnLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nameEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      nameEnBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nameEn',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      nameEnStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'nameEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      nameEnEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'nameEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      nameEnContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nameEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      nameEnMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nameEn',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      nameEnIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nameEn',
        value: '',
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      nameEnIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nameEn',
        value: '',
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      nameHuEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nameHu',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      nameHuGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'nameHu',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      nameHuLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'nameHu',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      nameHuBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'nameHu',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      nameHuStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'nameHu',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      nameHuEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'nameHu',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      nameHuContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nameHu',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      nameHuMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nameHu',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      nameHuIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nameHu',
        value: '',
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      nameHuIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nameHu',
        value: '',
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      orderIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'orderIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      orderIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'orderIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      orderIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'orderIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      orderIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'orderIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      slugEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'slug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      slugGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'slug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      slugLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'slug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      slugBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'slug',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      slugStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'slug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      slugEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'slug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      slugContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'slug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      slugMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'slug',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      slugIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'slug',
        value: '',
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      slugIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'slug',
        value: '',
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      updatedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      updatedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      updatedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'updatedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterFilterCondition>
      updatedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'updatedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension TopicCollectionQueryObject
    on QueryBuilder<TopicCollection, TopicCollection, QFilterCondition> {}

extension TopicCollectionQueryLinks
    on QueryBuilder<TopicCollection, TopicCollection, QFilterCondition> {}

extension TopicCollectionQuerySortBy
    on QueryBuilder<TopicCollection, TopicCollection, QSortBy> {
  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy>
      sortByDescriptionEn() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'descriptionEn', Sort.asc);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy>
      sortByDescriptionEnDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'descriptionEn', Sort.desc);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy>
      sortByDescriptionHu() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'descriptionHu', Sort.asc);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy>
      sortByDescriptionHuDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'descriptionHu', Sort.desc);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy>
      sortByIsPremium() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPremium', Sort.asc);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy>
      sortByIsPremiumDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPremium', Sort.desc);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy> sortByNameEn() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameEn', Sort.asc);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy>
      sortByNameEnDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameEn', Sort.desc);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy> sortByNameHu() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameHu', Sort.asc);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy>
      sortByNameHuDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameHu', Sort.desc);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy>
      sortByOrderIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderIndex', Sort.asc);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy>
      sortByOrderIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderIndex', Sort.desc);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy> sortBySlug() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slug', Sort.asc);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy>
      sortBySlugDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slug', Sort.desc);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy>
      sortByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy>
      sortByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension TopicCollectionQuerySortThenBy
    on QueryBuilder<TopicCollection, TopicCollection, QSortThenBy> {
  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy>
      thenByDescriptionEn() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'descriptionEn', Sort.asc);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy>
      thenByDescriptionEnDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'descriptionEn', Sort.desc);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy>
      thenByDescriptionHu() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'descriptionHu', Sort.asc);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy>
      thenByDescriptionHuDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'descriptionHu', Sort.desc);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy>
      thenByIsPremium() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPremium', Sort.asc);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy>
      thenByIsPremiumDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPremium', Sort.desc);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy> thenByNameEn() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameEn', Sort.asc);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy>
      thenByNameEnDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameEn', Sort.desc);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy> thenByNameHu() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameHu', Sort.asc);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy>
      thenByNameHuDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameHu', Sort.desc);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy>
      thenByOrderIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderIndex', Sort.asc);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy>
      thenByOrderIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderIndex', Sort.desc);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy> thenBySlug() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slug', Sort.asc);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy>
      thenBySlugDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slug', Sort.desc);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy>
      thenByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.asc);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QAfterSortBy>
      thenByUpdatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updatedAt', Sort.desc);
    });
  }
}

extension TopicCollectionQueryWhereDistinct
    on QueryBuilder<TopicCollection, TopicCollection, QDistinct> {
  QueryBuilder<TopicCollection, TopicCollection, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QDistinct>
      distinctByDescriptionEn({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'descriptionEn',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QDistinct>
      distinctByDescriptionHu({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'descriptionHu',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QDistinct>
      distinctByIsPremium() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isPremium');
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QDistinct> distinctByNameEn(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nameEn', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QDistinct> distinctByNameHu(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nameHu', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QDistinct>
      distinctByOrderIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'orderIndex');
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QDistinct> distinctBySlug(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'slug', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<TopicCollection, TopicCollection, QDistinct>
      distinctByUpdatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updatedAt');
    });
  }
}

extension TopicCollectionQueryProperty
    on QueryBuilder<TopicCollection, TopicCollection, QQueryProperty> {
  QueryBuilder<TopicCollection, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<TopicCollection, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<TopicCollection, String?, QQueryOperations>
      descriptionEnProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'descriptionEn');
    });
  }

  QueryBuilder<TopicCollection, String?, QQueryOperations>
      descriptionHuProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'descriptionHu');
    });
  }

  QueryBuilder<TopicCollection, bool, QQueryOperations> isPremiumProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isPremium');
    });
  }

  QueryBuilder<TopicCollection, String, QQueryOperations> nameEnProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nameEn');
    });
  }

  QueryBuilder<TopicCollection, String, QQueryOperations> nameHuProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nameHu');
    });
  }

  QueryBuilder<TopicCollection, int, QQueryOperations> orderIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'orderIndex');
    });
  }

  QueryBuilder<TopicCollection, String, QQueryOperations> slugProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'slug');
    });
  }

  QueryBuilder<TopicCollection, DateTime, QQueryOperations>
      updatedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updatedAt');
    });
  }
}
