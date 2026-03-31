// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'furniture_collection.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetFurnitureCollectionCollection on Isar {
  IsarCollection<FurnitureCollection> get furnitureCollections =>
      this.collection();
}

const FurnitureCollectionSchema = CollectionSchema(
  name: r'FurnitureCollection',
  id: 900430114144510848,
  properties: {
    r'assetPath': PropertySchema(
      id: 0,
      name: r'assetPath',
      type: IsarType.string,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'isLocked': PropertySchema(
      id: 2,
      name: r'isLocked',
      type: IsarType.bool,
    ),
    r'isPlaced': PropertySchema(
      id: 3,
      name: r'isPlaced',
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
    r'price': PropertySchema(
      id: 6,
      name: r'price',
      type: IsarType.long,
    ),
    r'slug': PropertySchema(
      id: 7,
      name: r'slug',
      type: IsarType.string,
    ),
    r'type': PropertySchema(
      id: 8,
      name: r'type',
      type: IsarType.string,
    ),
    r'unlockedAt': PropertySchema(
      id: 9,
      name: r'unlockedAt',
      type: IsarType.dateTime,
    ),
    r'x': PropertySchema(
      id: 10,
      name: r'x',
      type: IsarType.double,
    ),
    r'y': PropertySchema(
      id: 11,
      name: r'y',
      type: IsarType.double,
    ),
    r'z': PropertySchema(
      id: 12,
      name: r'z',
      type: IsarType.double,
    )
  },
  estimateSize: _furnitureCollectionEstimateSize,
  serialize: _furnitureCollectionSerialize,
  deserialize: _furnitureCollectionDeserialize,
  deserializeProp: _furnitureCollectionDeserializeProp,
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
  getId: _furnitureCollectionGetId,
  getLinks: _furnitureCollectionGetLinks,
  attach: _furnitureCollectionAttach,
  version: '3.1.0+1',
);

int _furnitureCollectionEstimateSize(
  FurnitureCollection object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.assetPath.length * 3;
  bytesCount += 3 + object.nameEn.length * 3;
  bytesCount += 3 + object.nameHu.length * 3;
  bytesCount += 3 + object.slug.length * 3;
  bytesCount += 3 + object.type.length * 3;
  return bytesCount;
}

void _furnitureCollectionSerialize(
  FurnitureCollection object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.assetPath);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeBool(offsets[2], object.isLocked);
  writer.writeBool(offsets[3], object.isPlaced);
  writer.writeString(offsets[4], object.nameEn);
  writer.writeString(offsets[5], object.nameHu);
  writer.writeLong(offsets[6], object.price);
  writer.writeString(offsets[7], object.slug);
  writer.writeString(offsets[8], object.type);
  writer.writeDateTime(offsets[9], object.unlockedAt);
  writer.writeDouble(offsets[10], object.x);
  writer.writeDouble(offsets[11], object.y);
  writer.writeDouble(offsets[12], object.z);
}

FurnitureCollection _furnitureCollectionDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = FurnitureCollection();
  object.assetPath = reader.readString(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.id = id;
  object.isLocked = reader.readBool(offsets[2]);
  object.isPlaced = reader.readBool(offsets[3]);
  object.nameEn = reader.readString(offsets[4]);
  object.nameHu = reader.readString(offsets[5]);
  object.price = reader.readLong(offsets[6]);
  object.slug = reader.readString(offsets[7]);
  object.type = reader.readString(offsets[8]);
  object.unlockedAt = reader.readDateTime(offsets[9]);
  object.x = reader.readDouble(offsets[10]);
  object.y = reader.readDouble(offsets[11]);
  object.z = reader.readDouble(offsets[12]);
  return object;
}

P _furnitureCollectionDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readBool(offset)) as P;
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
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readDateTime(offset)) as P;
    case 10:
      return (reader.readDouble(offset)) as P;
    case 11:
      return (reader.readDouble(offset)) as P;
    case 12:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _furnitureCollectionGetId(FurnitureCollection object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _furnitureCollectionGetLinks(
    FurnitureCollection object) {
  return [];
}

void _furnitureCollectionAttach(
    IsarCollection<dynamic> col, Id id, FurnitureCollection object) {
  object.id = id;
}

extension FurnitureCollectionByIndex on IsarCollection<FurnitureCollection> {
  Future<FurnitureCollection?> getBySlug(String slug) {
    return getByIndex(r'slug', [slug]);
  }

  FurnitureCollection? getBySlugSync(String slug) {
    return getByIndexSync(r'slug', [slug]);
  }

  Future<bool> deleteBySlug(String slug) {
    return deleteByIndex(r'slug', [slug]);
  }

  bool deleteBySlugSync(String slug) {
    return deleteByIndexSync(r'slug', [slug]);
  }

  Future<List<FurnitureCollection?>> getAllBySlug(List<String> slugValues) {
    final values = slugValues.map((e) => [e]).toList();
    return getAllByIndex(r'slug', values);
  }

  List<FurnitureCollection?> getAllBySlugSync(List<String> slugValues) {
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

  Future<Id> putBySlug(FurnitureCollection object) {
    return putByIndex(r'slug', object);
  }

  Id putBySlugSync(FurnitureCollection object, {bool saveLinks = true}) {
    return putByIndexSync(r'slug', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllBySlug(List<FurnitureCollection> objects) {
    return putAllByIndex(r'slug', objects);
  }

  List<Id> putAllBySlugSync(List<FurnitureCollection> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'slug', objects, saveLinks: saveLinks);
  }
}

extension FurnitureCollectionQueryWhereSort
    on QueryBuilder<FurnitureCollection, FurnitureCollection, QWhere> {
  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension FurnitureCollectionQueryWhere
    on QueryBuilder<FurnitureCollection, FurnitureCollection, QWhereClause> {
  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterWhereClause>
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

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterWhereClause>
      idBetween(
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

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterWhereClause>
      slugEqualTo(String slug) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'slug',
        value: [slug],
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterWhereClause>
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

extension FurnitureCollectionQueryFilter on QueryBuilder<FurnitureCollection,
    FurnitureCollection, QFilterCondition> {
  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      assetPathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'assetPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      assetPathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'assetPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      assetPathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'assetPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      assetPathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'assetPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      assetPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'assetPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      assetPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'assetPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      assetPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'assetPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      assetPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'assetPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      assetPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'assetPath',
        value: '',
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      assetPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'assetPath',
        value: '',
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
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

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
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

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
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

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
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

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
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

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
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

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      isLockedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isLocked',
        value: value,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      isPlacedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isPlaced',
        value: value,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
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

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
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

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
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

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
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

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
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

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
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

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      nameEnContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nameEn',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      nameEnMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nameEn',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      nameEnIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nameEn',
        value: '',
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      nameEnIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nameEn',
        value: '',
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
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

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
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

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
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

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
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

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
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

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
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

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      nameHuContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'nameHu',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      nameHuMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'nameHu',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      nameHuIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'nameHu',
        value: '',
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      nameHuIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'nameHu',
        value: '',
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      priceEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'price',
        value: value,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      priceGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'price',
        value: value,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      priceLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'price',
        value: value,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      priceBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'price',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
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

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
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

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
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

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
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

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
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

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
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

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      slugContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'slug',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      slugMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'slug',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      slugIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'slug',
        value: '',
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      slugIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'slug',
        value: '',
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      typeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      typeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      typeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      typeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      typeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      typeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      typeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      typeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'type',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      unlockedAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'unlockedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      unlockedAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'unlockedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      unlockedAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'unlockedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      unlockedAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'unlockedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      xEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'x',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      xGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'x',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      xLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'x',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      xBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'x',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      yEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'y',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      yGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'y',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      yLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'y',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      yBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'y',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      zEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'z',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      zGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'z',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      zLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'z',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterFilterCondition>
      zBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'z',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension FurnitureCollectionQueryObject on QueryBuilder<FurnitureCollection,
    FurnitureCollection, QFilterCondition> {}

extension FurnitureCollectionQueryLinks on QueryBuilder<FurnitureCollection,
    FurnitureCollection, QFilterCondition> {}

extension FurnitureCollectionQuerySortBy
    on QueryBuilder<FurnitureCollection, FurnitureCollection, QSortBy> {
  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      sortByAssetPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assetPath', Sort.asc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      sortByAssetPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assetPath', Sort.desc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      sortByIsLocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLocked', Sort.asc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      sortByIsLockedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLocked', Sort.desc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      sortByIsPlaced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPlaced', Sort.asc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      sortByIsPlacedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPlaced', Sort.desc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      sortByNameEn() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameEn', Sort.asc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      sortByNameEnDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameEn', Sort.desc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      sortByNameHu() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameHu', Sort.asc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      sortByNameHuDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameHu', Sort.desc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      sortByPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.asc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      sortByPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.desc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      sortBySlug() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slug', Sort.asc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      sortBySlugDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slug', Sort.desc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      sortByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      sortByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      sortByUnlockedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unlockedAt', Sort.asc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      sortByUnlockedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unlockedAt', Sort.desc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      sortByX() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'x', Sort.asc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      sortByXDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'x', Sort.desc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      sortByY() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'y', Sort.asc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      sortByYDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'y', Sort.desc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      sortByZ() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'z', Sort.asc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      sortByZDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'z', Sort.desc);
    });
  }
}

extension FurnitureCollectionQuerySortThenBy
    on QueryBuilder<FurnitureCollection, FurnitureCollection, QSortThenBy> {
  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      thenByAssetPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assetPath', Sort.asc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      thenByAssetPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'assetPath', Sort.desc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      thenByIsLocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLocked', Sort.asc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      thenByIsLockedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLocked', Sort.desc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      thenByIsPlaced() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPlaced', Sort.asc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      thenByIsPlacedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isPlaced', Sort.desc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      thenByNameEn() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameEn', Sort.asc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      thenByNameEnDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameEn', Sort.desc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      thenByNameHu() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameHu', Sort.asc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      thenByNameHuDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'nameHu', Sort.desc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      thenByPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.asc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      thenByPriceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'price', Sort.desc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      thenBySlug() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slug', Sort.asc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      thenBySlugDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'slug', Sort.desc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      thenByType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.asc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      thenByTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'type', Sort.desc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      thenByUnlockedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unlockedAt', Sort.asc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      thenByUnlockedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'unlockedAt', Sort.desc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      thenByX() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'x', Sort.asc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      thenByXDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'x', Sort.desc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      thenByY() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'y', Sort.asc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      thenByYDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'y', Sort.desc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      thenByZ() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'z', Sort.asc);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QAfterSortBy>
      thenByZDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'z', Sort.desc);
    });
  }
}

extension FurnitureCollectionQueryWhereDistinct
    on QueryBuilder<FurnitureCollection, FurnitureCollection, QDistinct> {
  QueryBuilder<FurnitureCollection, FurnitureCollection, QDistinct>
      distinctByAssetPath({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'assetPath', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QDistinct>
      distinctByIsLocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isLocked');
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QDistinct>
      distinctByIsPlaced() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isPlaced');
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QDistinct>
      distinctByNameEn({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nameEn', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QDistinct>
      distinctByNameHu({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'nameHu', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QDistinct>
      distinctByPrice() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'price');
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QDistinct>
      distinctBySlug({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'slug', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QDistinct>
      distinctByType({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'type', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QDistinct>
      distinctByUnlockedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'unlockedAt');
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QDistinct>
      distinctByX() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'x');
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QDistinct>
      distinctByY() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'y');
    });
  }

  QueryBuilder<FurnitureCollection, FurnitureCollection, QDistinct>
      distinctByZ() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'z');
    });
  }
}

extension FurnitureCollectionQueryProperty
    on QueryBuilder<FurnitureCollection, FurnitureCollection, QQueryProperty> {
  QueryBuilder<FurnitureCollection, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<FurnitureCollection, String, QQueryOperations>
      assetPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'assetPath');
    });
  }

  QueryBuilder<FurnitureCollection, DateTime, QQueryOperations>
      createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<FurnitureCollection, bool, QQueryOperations> isLockedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isLocked');
    });
  }

  QueryBuilder<FurnitureCollection, bool, QQueryOperations> isPlacedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isPlaced');
    });
  }

  QueryBuilder<FurnitureCollection, String, QQueryOperations> nameEnProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nameEn');
    });
  }

  QueryBuilder<FurnitureCollection, String, QQueryOperations> nameHuProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'nameHu');
    });
  }

  QueryBuilder<FurnitureCollection, int, QQueryOperations> priceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'price');
    });
  }

  QueryBuilder<FurnitureCollection, String, QQueryOperations> slugProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'slug');
    });
  }

  QueryBuilder<FurnitureCollection, String, QQueryOperations> typeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'type');
    });
  }

  QueryBuilder<FurnitureCollection, DateTime, QQueryOperations>
      unlockedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'unlockedAt');
    });
  }

  QueryBuilder<FurnitureCollection, double, QQueryOperations> xProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'x');
    });
  }

  QueryBuilder<FurnitureCollection, double, QQueryOperations> yProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'y');
    });
  }

  QueryBuilder<FurnitureCollection, double, QQueryOperations> zProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'z');
    });
  }
}
