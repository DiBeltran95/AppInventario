// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $UsuariosTable extends Usuarios with TableInfo<$UsuariosTable, Usuario> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsuariosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rolMeta = const VerificationMeta('rol');
  @override
  late final GeneratedColumn<String> rol = GeneratedColumn<String>(
    'rol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('VENDEDOR'),
  );
  static const VerificationMeta _activoMeta = const VerificationMeta('activo');
  @override
  late final GeneratedColumn<bool> activo = GeneratedColumn<bool>(
    'activo',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("activo" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _passwordHashLocalMeta = const VerificationMeta(
    'passwordHashLocal',
  );
  @override
  late final GeneratedColumn<String> passwordHashLocal =
      GeneratedColumn<String>(
        'password_hash_local',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _saltLocalMeta = const VerificationMeta(
    'saltLocal',
  );
  @override
  late final GeneratedColumn<String> saltLocal = GeneratedColumn<String>(
    'salt_local',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    nombre,
    email,
    rol,
    activo,
    passwordHashLocal,
    saltLocal,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'usuarios';
  @override
  VerificationContext validateIntegrity(
    Insertable<Usuario> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('rol')) {
      context.handle(
        _rolMeta,
        rol.isAcceptableOrUnknown(data['rol']!, _rolMeta),
      );
    }
    if (data.containsKey('activo')) {
      context.handle(
        _activoMeta,
        activo.isAcceptableOrUnknown(data['activo']!, _activoMeta),
      );
    }
    if (data.containsKey('password_hash_local')) {
      context.handle(
        _passwordHashLocalMeta,
        passwordHashLocal.isAcceptableOrUnknown(
          data['password_hash_local']!,
          _passwordHashLocalMeta,
        ),
      );
    }
    if (data.containsKey('salt_local')) {
      context.handle(
        _saltLocalMeta,
        saltLocal.isAcceptableOrUnknown(data['salt_local']!, _saltLocalMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  Usuario map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Usuario(
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      rol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rol'],
      )!,
      activo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}activo'],
      )!,
      passwordHashLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password_hash_local'],
      ),
      saltLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}salt_local'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $UsuariosTable createAlias(String alias) {
    return $UsuariosTable(attachedDatabase, alias);
  }
}

class Usuario extends DataClass implements Insertable<Usuario> {
  final String uuid;
  final String nombre;
  final String email;
  final String rol;
  final bool activo;

  /// Hash PBKDF2 de la contraseña, calculado **en el dispositivo** con su
  /// propia sal. Permite iniciar sesión sin red. El hash del servidor jamás
  /// viaja hasta aquí: si robaran el teléfono, no obtendrían la credencial del
  /// servidor, sólo un derivado local.
  final String? passwordHashLocal;
  final String? saltLocal;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const Usuario({
    required this.uuid,
    required this.nombre,
    required this.email,
    required this.rol,
    required this.activo,
    this.passwordHashLocal,
    this.saltLocal,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid'] = Variable<String>(uuid);
    map['nombre'] = Variable<String>(nombre);
    map['email'] = Variable<String>(email);
    map['rol'] = Variable<String>(rol);
    map['activo'] = Variable<bool>(activo);
    if (!nullToAbsent || passwordHashLocal != null) {
      map['password_hash_local'] = Variable<String>(passwordHashLocal);
    }
    if (!nullToAbsent || saltLocal != null) {
      map['salt_local'] = Variable<String>(saltLocal);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  UsuariosCompanion toCompanion(bool nullToAbsent) {
    return UsuariosCompanion(
      uuid: Value(uuid),
      nombre: Value(nombre),
      email: Value(email),
      rol: Value(rol),
      activo: Value(activo),
      passwordHashLocal: passwordHashLocal == null && nullToAbsent
          ? const Value.absent()
          : Value(passwordHashLocal),
      saltLocal: saltLocal == null && nullToAbsent
          ? const Value.absent()
          : Value(saltLocal),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Usuario.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Usuario(
      uuid: serializer.fromJson<String>(json['uuid']),
      nombre: serializer.fromJson<String>(json['nombre']),
      email: serializer.fromJson<String>(json['email']),
      rol: serializer.fromJson<String>(json['rol']),
      activo: serializer.fromJson<bool>(json['activo']),
      passwordHashLocal: serializer.fromJson<String?>(
        json['passwordHashLocal'],
      ),
      saltLocal: serializer.fromJson<String?>(json['saltLocal']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String>(uuid),
      'nombre': serializer.toJson<String>(nombre),
      'email': serializer.toJson<String>(email),
      'rol': serializer.toJson<String>(rol),
      'activo': serializer.toJson<bool>(activo),
      'passwordHashLocal': serializer.toJson<String?>(passwordHashLocal),
      'saltLocal': serializer.toJson<String?>(saltLocal),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Usuario copyWith({
    String? uuid,
    String? nombre,
    String? email,
    String? rol,
    bool? activo,
    Value<String?> passwordHashLocal = const Value.absent(),
    Value<String?> saltLocal = const Value.absent(),
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Usuario(
    uuid: uuid ?? this.uuid,
    nombre: nombre ?? this.nombre,
    email: email ?? this.email,
    rol: rol ?? this.rol,
    activo: activo ?? this.activo,
    passwordHashLocal: passwordHashLocal.present
        ? passwordHashLocal.value
        : this.passwordHashLocal,
    saltLocal: saltLocal.present ? saltLocal.value : this.saltLocal,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Usuario copyWithCompanion(UsuariosCompanion data) {
    return Usuario(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      email: data.email.present ? data.email.value : this.email,
      rol: data.rol.present ? data.rol.value : this.rol,
      activo: data.activo.present ? data.activo.value : this.activo,
      passwordHashLocal: data.passwordHashLocal.present
          ? data.passwordHashLocal.value
          : this.passwordHashLocal,
      saltLocal: data.saltLocal.present ? data.saltLocal.value : this.saltLocal,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Usuario(')
          ..write('uuid: $uuid, ')
          ..write('nombre: $nombre, ')
          ..write('email: $email, ')
          ..write('rol: $rol, ')
          ..write('activo: $activo, ')
          ..write('passwordHashLocal: $passwordHashLocal, ')
          ..write('saltLocal: $saltLocal, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    nombre,
    email,
    rol,
    activo,
    passwordHashLocal,
    saltLocal,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Usuario &&
          other.uuid == this.uuid &&
          other.nombre == this.nombre &&
          other.email == this.email &&
          other.rol == this.rol &&
          other.activo == this.activo &&
          other.passwordHashLocal == this.passwordHashLocal &&
          other.saltLocal == this.saltLocal &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class UsuariosCompanion extends UpdateCompanion<Usuario> {
  final Value<String> uuid;
  final Value<String> nombre;
  final Value<String> email;
  final Value<String> rol;
  final Value<bool> activo;
  final Value<String?> passwordHashLocal;
  final Value<String?> saltLocal;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const UsuariosCompanion({
    this.uuid = const Value.absent(),
    this.nombre = const Value.absent(),
    this.email = const Value.absent(),
    this.rol = const Value.absent(),
    this.activo = const Value.absent(),
    this.passwordHashLocal = const Value.absent(),
    this.saltLocal = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsuariosCompanion.insert({
    required String uuid,
    required String nombre,
    required String email,
    this.rol = const Value.absent(),
    this.activo = const Value.absent(),
    this.passwordHashLocal = const Value.absent(),
    this.saltLocal = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       nombre = Value(nombre),
       email = Value(email);
  static Insertable<Usuario> custom({
    Expression<String>? uuid,
    Expression<String>? nombre,
    Expression<String>? email,
    Expression<String>? rol,
    Expression<bool>? activo,
    Expression<String>? passwordHashLocal,
    Expression<String>? saltLocal,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (nombre != null) 'nombre': nombre,
      if (email != null) 'email': email,
      if (rol != null) 'rol': rol,
      if (activo != null) 'activo': activo,
      if (passwordHashLocal != null) 'password_hash_local': passwordHashLocal,
      if (saltLocal != null) 'salt_local': saltLocal,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsuariosCompanion copyWith({
    Value<String>? uuid,
    Value<String>? nombre,
    Value<String>? email,
    Value<String>? rol,
    Value<bool>? activo,
    Value<String?>? passwordHashLocal,
    Value<String?>? saltLocal,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return UsuariosCompanion(
      uuid: uuid ?? this.uuid,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      rol: rol ?? this.rol,
      activo: activo ?? this.activo,
      passwordHashLocal: passwordHashLocal ?? this.passwordHashLocal,
      saltLocal: saltLocal ?? this.saltLocal,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (rol.present) {
      map['rol'] = Variable<String>(rol.value);
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
    }
    if (passwordHashLocal.present) {
      map['password_hash_local'] = Variable<String>(passwordHashLocal.value);
    }
    if (saltLocal.present) {
      map['salt_local'] = Variable<String>(saltLocal.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsuariosCompanion(')
          ..write('uuid: $uuid, ')
          ..write('nombre: $nombre, ')
          ..write('email: $email, ')
          ..write('rol: $rol, ')
          ..write('activo: $activo, ')
          ..write('passwordHashLocal: $passwordHashLocal, ')
          ..write('saltLocal: $saltLocal, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriasTable extends Categorias
    with TableInfo<$CategoriasTable, Categoria> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descripcionMeta = const VerificationMeta(
    'descripcion',
  );
  @override
  late final GeneratedColumn<String> descripcion = GeneratedColumn<String>(
    'descripcion',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('#6750A4'),
  );
  static const VerificationMeta _iconoMeta = const VerificationMeta('icono');
  @override
  late final GeneratedColumn<String> icono = GeneratedColumn<String>(
    'icono',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ordenMeta = const VerificationMeta('orden');
  @override
  late final GeneratedColumn<int> orden = GeneratedColumn<int>(
    'orden',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    nombre,
    descripcion,
    color,
    icono,
    orden,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categorias';
  @override
  VerificationContext validateIntegrity(
    Insertable<Categoria> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('descripcion')) {
      context.handle(
        _descripcionMeta,
        descripcion.isAcceptableOrUnknown(
          data['descripcion']!,
          _descripcionMeta,
        ),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('icono')) {
      context.handle(
        _iconoMeta,
        icono.isAcceptableOrUnknown(data['icono']!, _iconoMeta),
      );
    }
    if (data.containsKey('orden')) {
      context.handle(
        _ordenMeta,
        orden.isAcceptableOrUnknown(data['orden']!, _ordenMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  Categoria map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Categoria(
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      descripcion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}descripcion'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      )!,
      icono: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icono'],
      ),
      orden: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}orden'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $CategoriasTable createAlias(String alias) {
    return $CategoriasTable(attachedDatabase, alias);
  }
}

class Categoria extends DataClass implements Insertable<Categoria> {
  final String uuid;
  final String nombre;
  final String? descripcion;
  final String color;
  final String? icono;
  final int orden;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const Categoria({
    required this.uuid,
    required this.nombre,
    this.descripcion,
    required this.color,
    this.icono,
    required this.orden,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid'] = Variable<String>(uuid);
    map['nombre'] = Variable<String>(nombre);
    if (!nullToAbsent || descripcion != null) {
      map['descripcion'] = Variable<String>(descripcion);
    }
    map['color'] = Variable<String>(color);
    if (!nullToAbsent || icono != null) {
      map['icono'] = Variable<String>(icono);
    }
    map['orden'] = Variable<int>(orden);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  CategoriasCompanion toCompanion(bool nullToAbsent) {
    return CategoriasCompanion(
      uuid: Value(uuid),
      nombre: Value(nombre),
      descripcion: descripcion == null && nullToAbsent
          ? const Value.absent()
          : Value(descripcion),
      color: Value(color),
      icono: icono == null && nullToAbsent
          ? const Value.absent()
          : Value(icono),
      orden: Value(orden),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Categoria.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Categoria(
      uuid: serializer.fromJson<String>(json['uuid']),
      nombre: serializer.fromJson<String>(json['nombre']),
      descripcion: serializer.fromJson<String?>(json['descripcion']),
      color: serializer.fromJson<String>(json['color']),
      icono: serializer.fromJson<String?>(json['icono']),
      orden: serializer.fromJson<int>(json['orden']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String>(uuid),
      'nombre': serializer.toJson<String>(nombre),
      'descripcion': serializer.toJson<String?>(descripcion),
      'color': serializer.toJson<String>(color),
      'icono': serializer.toJson<String?>(icono),
      'orden': serializer.toJson<int>(orden),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Categoria copyWith({
    String? uuid,
    String? nombre,
    Value<String?> descripcion = const Value.absent(),
    String? color,
    Value<String?> icono = const Value.absent(),
    int? orden,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Categoria(
    uuid: uuid ?? this.uuid,
    nombre: nombre ?? this.nombre,
    descripcion: descripcion.present ? descripcion.value : this.descripcion,
    color: color ?? this.color,
    icono: icono.present ? icono.value : this.icono,
    orden: orden ?? this.orden,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Categoria copyWithCompanion(CategoriasCompanion data) {
    return Categoria(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      descripcion: data.descripcion.present
          ? data.descripcion.value
          : this.descripcion,
      color: data.color.present ? data.color.value : this.color,
      icono: data.icono.present ? data.icono.value : this.icono,
      orden: data.orden.present ? data.orden.value : this.orden,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Categoria(')
          ..write('uuid: $uuid, ')
          ..write('nombre: $nombre, ')
          ..write('descripcion: $descripcion, ')
          ..write('color: $color, ')
          ..write('icono: $icono, ')
          ..write('orden: $orden, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    nombre,
    descripcion,
    color,
    icono,
    orden,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Categoria &&
          other.uuid == this.uuid &&
          other.nombre == this.nombre &&
          other.descripcion == this.descripcion &&
          other.color == this.color &&
          other.icono == this.icono &&
          other.orden == this.orden &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class CategoriasCompanion extends UpdateCompanion<Categoria> {
  final Value<String> uuid;
  final Value<String> nombre;
  final Value<String?> descripcion;
  final Value<String> color;
  final Value<String?> icono;
  final Value<int> orden;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const CategoriasCompanion({
    this.uuid = const Value.absent(),
    this.nombre = const Value.absent(),
    this.descripcion = const Value.absent(),
    this.color = const Value.absent(),
    this.icono = const Value.absent(),
    this.orden = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriasCompanion.insert({
    required String uuid,
    required String nombre,
    this.descripcion = const Value.absent(),
    this.color = const Value.absent(),
    this.icono = const Value.absent(),
    this.orden = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       nombre = Value(nombre);
  static Insertable<Categoria> custom({
    Expression<String>? uuid,
    Expression<String>? nombre,
    Expression<String>? descripcion,
    Expression<String>? color,
    Expression<String>? icono,
    Expression<int>? orden,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (nombre != null) 'nombre': nombre,
      if (descripcion != null) 'descripcion': descripcion,
      if (color != null) 'color': color,
      if (icono != null) 'icono': icono,
      if (orden != null) 'orden': orden,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriasCompanion copyWith({
    Value<String>? uuid,
    Value<String>? nombre,
    Value<String?>? descripcion,
    Value<String>? color,
    Value<String?>? icono,
    Value<int>? orden,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return CategoriasCompanion(
      uuid: uuid ?? this.uuid,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      color: color ?? this.color,
      icono: icono ?? this.icono,
      orden: orden ?? this.orden,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (descripcion.present) {
      map['descripcion'] = Variable<String>(descripcion.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (icono.present) {
      map['icono'] = Variable<String>(icono.value);
    }
    if (orden.present) {
      map['orden'] = Variable<int>(orden.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriasCompanion(')
          ..write('uuid: $uuid, ')
          ..write('nombre: $nombre, ')
          ..write('descripcion: $descripcion, ')
          ..write('color: $color, ')
          ..write('icono: $icono, ')
          ..write('orden: $orden, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProveedoresTable extends Proveedores
    with TableInfo<$ProveedoresTable, Proveedor> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProveedoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nitMeta = const VerificationMeta('nit');
  @override
  late final GeneratedColumn<String> nit = GeneratedColumn<String>(
    'nit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contactoMeta = const VerificationMeta(
    'contacto',
  );
  @override
  late final GeneratedColumn<String> contacto = GeneratedColumn<String>(
    'contacto',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _telefonoMeta = const VerificationMeta(
    'telefono',
  );
  @override
  late final GeneratedColumn<String> telefono = GeneratedColumn<String>(
    'telefono',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _direccionMeta = const VerificationMeta(
    'direccion',
  );
  @override
  late final GeneratedColumn<String> direccion = GeneratedColumn<String>(
    'direccion',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notasMeta = const VerificationMeta('notas');
  @override
  late final GeneratedColumn<String> notas = GeneratedColumn<String>(
    'notas',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    nombre,
    nit,
    contacto,
    telefono,
    email,
    direccion,
    notas,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'proveedores';
  @override
  VerificationContext validateIntegrity(
    Insertable<Proveedor> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('nit')) {
      context.handle(
        _nitMeta,
        nit.isAcceptableOrUnknown(data['nit']!, _nitMeta),
      );
    }
    if (data.containsKey('contacto')) {
      context.handle(
        _contactoMeta,
        contacto.isAcceptableOrUnknown(data['contacto']!, _contactoMeta),
      );
    }
    if (data.containsKey('telefono')) {
      context.handle(
        _telefonoMeta,
        telefono.isAcceptableOrUnknown(data['telefono']!, _telefonoMeta),
      );
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    }
    if (data.containsKey('direccion')) {
      context.handle(
        _direccionMeta,
        direccion.isAcceptableOrUnknown(data['direccion']!, _direccionMeta),
      );
    }
    if (data.containsKey('notas')) {
      context.handle(
        _notasMeta,
        notas.isAcceptableOrUnknown(data['notas']!, _notasMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  Proveedor map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Proveedor(
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      nit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nit'],
      ),
      contacto: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}contacto'],
      ),
      telefono: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}telefono'],
      ),
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      ),
      direccion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}direccion'],
      ),
      notas: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notas'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $ProveedoresTable createAlias(String alias) {
    return $ProveedoresTable(attachedDatabase, alias);
  }
}

class Proveedor extends DataClass implements Insertable<Proveedor> {
  final String uuid;
  final String nombre;
  final String? nit;
  final String? contacto;
  final String? telefono;
  final String? email;
  final String? direccion;
  final String? notas;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const Proveedor({
    required this.uuid,
    required this.nombre,
    this.nit,
    this.contacto,
    this.telefono,
    this.email,
    this.direccion,
    this.notas,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid'] = Variable<String>(uuid);
    map['nombre'] = Variable<String>(nombre);
    if (!nullToAbsent || nit != null) {
      map['nit'] = Variable<String>(nit);
    }
    if (!nullToAbsent || contacto != null) {
      map['contacto'] = Variable<String>(contacto);
    }
    if (!nullToAbsent || telefono != null) {
      map['telefono'] = Variable<String>(telefono);
    }
    if (!nullToAbsent || email != null) {
      map['email'] = Variable<String>(email);
    }
    if (!nullToAbsent || direccion != null) {
      map['direccion'] = Variable<String>(direccion);
    }
    if (!nullToAbsent || notas != null) {
      map['notas'] = Variable<String>(notas);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  ProveedoresCompanion toCompanion(bool nullToAbsent) {
    return ProveedoresCompanion(
      uuid: Value(uuid),
      nombre: Value(nombre),
      nit: nit == null && nullToAbsent ? const Value.absent() : Value(nit),
      contacto: contacto == null && nullToAbsent
          ? const Value.absent()
          : Value(contacto),
      telefono: telefono == null && nullToAbsent
          ? const Value.absent()
          : Value(telefono),
      email: email == null && nullToAbsent
          ? const Value.absent()
          : Value(email),
      direccion: direccion == null && nullToAbsent
          ? const Value.absent()
          : Value(direccion),
      notas: notas == null && nullToAbsent
          ? const Value.absent()
          : Value(notas),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Proveedor.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Proveedor(
      uuid: serializer.fromJson<String>(json['uuid']),
      nombre: serializer.fromJson<String>(json['nombre']),
      nit: serializer.fromJson<String?>(json['nit']),
      contacto: serializer.fromJson<String?>(json['contacto']),
      telefono: serializer.fromJson<String?>(json['telefono']),
      email: serializer.fromJson<String?>(json['email']),
      direccion: serializer.fromJson<String?>(json['direccion']),
      notas: serializer.fromJson<String?>(json['notas']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String>(uuid),
      'nombre': serializer.toJson<String>(nombre),
      'nit': serializer.toJson<String?>(nit),
      'contacto': serializer.toJson<String?>(contacto),
      'telefono': serializer.toJson<String?>(telefono),
      'email': serializer.toJson<String?>(email),
      'direccion': serializer.toJson<String?>(direccion),
      'notas': serializer.toJson<String?>(notas),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Proveedor copyWith({
    String? uuid,
    String? nombre,
    Value<String?> nit = const Value.absent(),
    Value<String?> contacto = const Value.absent(),
    Value<String?> telefono = const Value.absent(),
    Value<String?> email = const Value.absent(),
    Value<String?> direccion = const Value.absent(),
    Value<String?> notas = const Value.absent(),
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Proveedor(
    uuid: uuid ?? this.uuid,
    nombre: nombre ?? this.nombre,
    nit: nit.present ? nit.value : this.nit,
    contacto: contacto.present ? contacto.value : this.contacto,
    telefono: telefono.present ? telefono.value : this.telefono,
    email: email.present ? email.value : this.email,
    direccion: direccion.present ? direccion.value : this.direccion,
    notas: notas.present ? notas.value : this.notas,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Proveedor copyWithCompanion(ProveedoresCompanion data) {
    return Proveedor(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      nit: data.nit.present ? data.nit.value : this.nit,
      contacto: data.contacto.present ? data.contacto.value : this.contacto,
      telefono: data.telefono.present ? data.telefono.value : this.telefono,
      email: data.email.present ? data.email.value : this.email,
      direccion: data.direccion.present ? data.direccion.value : this.direccion,
      notas: data.notas.present ? data.notas.value : this.notas,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Proveedor(')
          ..write('uuid: $uuid, ')
          ..write('nombre: $nombre, ')
          ..write('nit: $nit, ')
          ..write('contacto: $contacto, ')
          ..write('telefono: $telefono, ')
          ..write('email: $email, ')
          ..write('direccion: $direccion, ')
          ..write('notas: $notas, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    nombre,
    nit,
    contacto,
    telefono,
    email,
    direccion,
    notas,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Proveedor &&
          other.uuid == this.uuid &&
          other.nombre == this.nombre &&
          other.nit == this.nit &&
          other.contacto == this.contacto &&
          other.telefono == this.telefono &&
          other.email == this.email &&
          other.direccion == this.direccion &&
          other.notas == this.notas &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class ProveedoresCompanion extends UpdateCompanion<Proveedor> {
  final Value<String> uuid;
  final Value<String> nombre;
  final Value<String?> nit;
  final Value<String?> contacto;
  final Value<String?> telefono;
  final Value<String?> email;
  final Value<String?> direccion;
  final Value<String?> notas;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const ProveedoresCompanion({
    this.uuid = const Value.absent(),
    this.nombre = const Value.absent(),
    this.nit = const Value.absent(),
    this.contacto = const Value.absent(),
    this.telefono = const Value.absent(),
    this.email = const Value.absent(),
    this.direccion = const Value.absent(),
    this.notas = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProveedoresCompanion.insert({
    required String uuid,
    required String nombre,
    this.nit = const Value.absent(),
    this.contacto = const Value.absent(),
    this.telefono = const Value.absent(),
    this.email = const Value.absent(),
    this.direccion = const Value.absent(),
    this.notas = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       nombre = Value(nombre);
  static Insertable<Proveedor> custom({
    Expression<String>? uuid,
    Expression<String>? nombre,
    Expression<String>? nit,
    Expression<String>? contacto,
    Expression<String>? telefono,
    Expression<String>? email,
    Expression<String>? direccion,
    Expression<String>? notas,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (nombre != null) 'nombre': nombre,
      if (nit != null) 'nit': nit,
      if (contacto != null) 'contacto': contacto,
      if (telefono != null) 'telefono': telefono,
      if (email != null) 'email': email,
      if (direccion != null) 'direccion': direccion,
      if (notas != null) 'notas': notas,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProveedoresCompanion copyWith({
    Value<String>? uuid,
    Value<String>? nombre,
    Value<String?>? nit,
    Value<String?>? contacto,
    Value<String?>? telefono,
    Value<String?>? email,
    Value<String?>? direccion,
    Value<String?>? notas,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return ProveedoresCompanion(
      uuid: uuid ?? this.uuid,
      nombre: nombre ?? this.nombre,
      nit: nit ?? this.nit,
      contacto: contacto ?? this.contacto,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      direccion: direccion ?? this.direccion,
      notas: notas ?? this.notas,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (nit.present) {
      map['nit'] = Variable<String>(nit.value);
    }
    if (contacto.present) {
      map['contacto'] = Variable<String>(contacto.value);
    }
    if (telefono.present) {
      map['telefono'] = Variable<String>(telefono.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (direccion.present) {
      map['direccion'] = Variable<String>(direccion.value);
    }
    if (notas.present) {
      map['notas'] = Variable<String>(notas.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProveedoresCompanion(')
          ..write('uuid: $uuid, ')
          ..write('nombre: $nombre, ')
          ..write('nit: $nit, ')
          ..write('contacto: $contacto, ')
          ..write('telefono: $telefono, ')
          ..write('email: $email, ')
          ..write('direccion: $direccion, ')
          ..write('notas: $notas, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductosTable extends Productos
    with TableInfo<$ProductosTable, Producto> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _skuMeta = const VerificationMeta('sku');
  @override
  late final GeneratedColumn<String> sku = GeneratedColumn<String>(
    'sku',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreMeta = const VerificationMeta('nombre');
  @override
  late final GeneratedColumn<String> nombre = GeneratedColumn<String>(
    'nombre',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nombreBusquedaMeta = const VerificationMeta(
    'nombreBusqueda',
  );
  @override
  late final GeneratedColumn<String> nombreBusqueda = GeneratedColumn<String>(
    'nombre_busqueda',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _descripcionMeta = const VerificationMeta(
    'descripcion',
  );
  @override
  late final GeneratedColumn<String> descripcion = GeneratedColumn<String>(
    'descripcion',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoriaUuidMeta = const VerificationMeta(
    'categoriaUuid',
  );
  @override
  late final GeneratedColumn<String> categoriaUuid = GeneratedColumn<String>(
    'categoria_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unidadMedidaMeta = const VerificationMeta(
    'unidadMedida',
  );
  @override
  late final GeneratedColumn<String> unidadMedida = GeneratedColumn<String>(
    'unidad_medida',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('UND'),
  );
  static const VerificationMeta _precioCompraMeta = const VerificationMeta(
    'precioCompra',
  );
  @override
  late final GeneratedColumn<int> precioCompra = GeneratedColumn<int>(
    'precio_compra',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _precioVentaMeta = const VerificationMeta(
    'precioVenta',
  );
  @override
  late final GeneratedColumn<int> precioVenta = GeneratedColumn<int>(
    'precio_venta',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _tasaIvaMeta = const VerificationMeta(
    'tasaIva',
  );
  @override
  late final GeneratedColumn<int> tasaIva = GeneratedColumn<int>(
    'tasa_iva',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1900),
  );
  static const VerificationMeta _stockActualMeta = const VerificationMeta(
    'stockActual',
  );
  @override
  late final GeneratedColumn<int> stockActual = GeneratedColumn<int>(
    'stock_actual',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _stockMinimoMeta = const VerificationMeta(
    'stockMinimo',
  );
  @override
  late final GeneratedColumn<int> stockMinimo = GeneratedColumn<int>(
    'stock_minimo',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _stockMaximoMeta = const VerificationMeta(
    'stockMaximo',
  );
  @override
  late final GeneratedColumn<int> stockMaximo = GeneratedColumn<int>(
    'stock_maximo',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imagenUrlMeta = const VerificationMeta(
    'imagenUrl',
  );
  @override
  late final GeneratedColumn<String> imagenUrl = GeneratedColumn<String>(
    'imagen_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imagenLocalMeta = const VerificationMeta(
    'imagenLocal',
  );
  @override
  late final GeneratedColumn<String> imagenLocal = GeneratedColumn<String>(
    'imagen_local',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ubicacionMeta = const VerificationMeta(
    'ubicacion',
  );
  @override
  late final GeneratedColumn<String> ubicacion = GeneratedColumn<String>(
    'ubicacion',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activoMeta = const VerificationMeta('activo');
  @override
  late final GeneratedColumn<bool> activo = GeneratedColumn<bool>(
    'activo',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("activo" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    sku,
    nombre,
    nombreBusqueda,
    descripcion,
    categoriaUuid,
    unidadMedida,
    precioCompra,
    precioVenta,
    tasaIva,
    stockActual,
    stockMinimo,
    stockMaximo,
    imagenUrl,
    imagenLocal,
    ubicacion,
    activo,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'productos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Producto> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('sku')) {
      context.handle(
        _skuMeta,
        sku.isAcceptableOrUnknown(data['sku']!, _skuMeta),
      );
    } else if (isInserting) {
      context.missing(_skuMeta);
    }
    if (data.containsKey('nombre')) {
      context.handle(
        _nombreMeta,
        nombre.isAcceptableOrUnknown(data['nombre']!, _nombreMeta),
      );
    } else if (isInserting) {
      context.missing(_nombreMeta);
    }
    if (data.containsKey('nombre_busqueda')) {
      context.handle(
        _nombreBusquedaMeta,
        nombreBusqueda.isAcceptableOrUnknown(
          data['nombre_busqueda']!,
          _nombreBusquedaMeta,
        ),
      );
    }
    if (data.containsKey('descripcion')) {
      context.handle(
        _descripcionMeta,
        descripcion.isAcceptableOrUnknown(
          data['descripcion']!,
          _descripcionMeta,
        ),
      );
    }
    if (data.containsKey('categoria_uuid')) {
      context.handle(
        _categoriaUuidMeta,
        categoriaUuid.isAcceptableOrUnknown(
          data['categoria_uuid']!,
          _categoriaUuidMeta,
        ),
      );
    }
    if (data.containsKey('unidad_medida')) {
      context.handle(
        _unidadMedidaMeta,
        unidadMedida.isAcceptableOrUnknown(
          data['unidad_medida']!,
          _unidadMedidaMeta,
        ),
      );
    }
    if (data.containsKey('precio_compra')) {
      context.handle(
        _precioCompraMeta,
        precioCompra.isAcceptableOrUnknown(
          data['precio_compra']!,
          _precioCompraMeta,
        ),
      );
    }
    if (data.containsKey('precio_venta')) {
      context.handle(
        _precioVentaMeta,
        precioVenta.isAcceptableOrUnknown(
          data['precio_venta']!,
          _precioVentaMeta,
        ),
      );
    }
    if (data.containsKey('tasa_iva')) {
      context.handle(
        _tasaIvaMeta,
        tasaIva.isAcceptableOrUnknown(data['tasa_iva']!, _tasaIvaMeta),
      );
    }
    if (data.containsKey('stock_actual')) {
      context.handle(
        _stockActualMeta,
        stockActual.isAcceptableOrUnknown(
          data['stock_actual']!,
          _stockActualMeta,
        ),
      );
    }
    if (data.containsKey('stock_minimo')) {
      context.handle(
        _stockMinimoMeta,
        stockMinimo.isAcceptableOrUnknown(
          data['stock_minimo']!,
          _stockMinimoMeta,
        ),
      );
    }
    if (data.containsKey('stock_maximo')) {
      context.handle(
        _stockMaximoMeta,
        stockMaximo.isAcceptableOrUnknown(
          data['stock_maximo']!,
          _stockMaximoMeta,
        ),
      );
    }
    if (data.containsKey('imagen_url')) {
      context.handle(
        _imagenUrlMeta,
        imagenUrl.isAcceptableOrUnknown(data['imagen_url']!, _imagenUrlMeta),
      );
    }
    if (data.containsKey('imagen_local')) {
      context.handle(
        _imagenLocalMeta,
        imagenLocal.isAcceptableOrUnknown(
          data['imagen_local']!,
          _imagenLocalMeta,
        ),
      );
    }
    if (data.containsKey('ubicacion')) {
      context.handle(
        _ubicacionMeta,
        ubicacion.isAcceptableOrUnknown(data['ubicacion']!, _ubicacionMeta),
      );
    }
    if (data.containsKey('activo')) {
      context.handle(
        _activoMeta,
        activo.isAcceptableOrUnknown(data['activo']!, _activoMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  Producto map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Producto(
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      sku: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sku'],
      )!,
      nombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre'],
      )!,
      nombreBusqueda: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nombre_busqueda'],
      )!,
      descripcion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}descripcion'],
      ),
      categoriaUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}categoria_uuid'],
      ),
      unidadMedida: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unidad_medida'],
      )!,
      precioCompra: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}precio_compra'],
      )!,
      precioVenta: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}precio_venta'],
      )!,
      tasaIva: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tasa_iva'],
      )!,
      stockActual: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stock_actual'],
      )!,
      stockMinimo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stock_minimo'],
      )!,
      stockMaximo: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stock_maximo'],
      ),
      imagenUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}imagen_url'],
      ),
      imagenLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}imagen_local'],
      ),
      ubicacion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ubicacion'],
      ),
      activo: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}activo'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $ProductosTable createAlias(String alias) {
    return $ProductosTable(attachedDatabase, alias);
  }
}

class Producto extends DataClass implements Insertable<Producto> {
  final String uuid;
  final String sku;
  final String nombre;

  /// Copia en minúsculas y sin tildes de `nombre`, para que la búsqueda
  /// «gaseosa» encuentre «Gaseosa» y «cafe» encuentre «Café» sin recorrer
  /// 10.000 filas en Dart. SQLite no normaliza Unicode por su cuenta.
  final String nombreBusqueda;
  final String? descripcion;
  final String? categoriaUuid;
  final String unidadMedida;
  final int precioCompra;
  final int precioVenta;
  final int tasaIva;

  /// Proyección local. Sólo la escribe `InventarioDao._aplicarMovimiento`.
  final int stockActual;
  final int stockMinimo;
  final int? stockMaximo;
  final String? imagenUrl;

  /// Ruta en el almacenamiento del dispositivo mientras la foto no se ha
  /// subido. La app muestra ésta hasta que la sincronización devuelve la URL.
  final String? imagenLocal;
  final String? ubicacion;
  final bool activo;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const Producto({
    required this.uuid,
    required this.sku,
    required this.nombre,
    required this.nombreBusqueda,
    this.descripcion,
    this.categoriaUuid,
    required this.unidadMedida,
    required this.precioCompra,
    required this.precioVenta,
    required this.tasaIva,
    required this.stockActual,
    required this.stockMinimo,
    this.stockMaximo,
    this.imagenUrl,
    this.imagenLocal,
    this.ubicacion,
    required this.activo,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid'] = Variable<String>(uuid);
    map['sku'] = Variable<String>(sku);
    map['nombre'] = Variable<String>(nombre);
    map['nombre_busqueda'] = Variable<String>(nombreBusqueda);
    if (!nullToAbsent || descripcion != null) {
      map['descripcion'] = Variable<String>(descripcion);
    }
    if (!nullToAbsent || categoriaUuid != null) {
      map['categoria_uuid'] = Variable<String>(categoriaUuid);
    }
    map['unidad_medida'] = Variable<String>(unidadMedida);
    map['precio_compra'] = Variable<int>(precioCompra);
    map['precio_venta'] = Variable<int>(precioVenta);
    map['tasa_iva'] = Variable<int>(tasaIva);
    map['stock_actual'] = Variable<int>(stockActual);
    map['stock_minimo'] = Variable<int>(stockMinimo);
    if (!nullToAbsent || stockMaximo != null) {
      map['stock_maximo'] = Variable<int>(stockMaximo);
    }
    if (!nullToAbsent || imagenUrl != null) {
      map['imagen_url'] = Variable<String>(imagenUrl);
    }
    if (!nullToAbsent || imagenLocal != null) {
      map['imagen_local'] = Variable<String>(imagenLocal);
    }
    if (!nullToAbsent || ubicacion != null) {
      map['ubicacion'] = Variable<String>(ubicacion);
    }
    map['activo'] = Variable<bool>(activo);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  ProductosCompanion toCompanion(bool nullToAbsent) {
    return ProductosCompanion(
      uuid: Value(uuid),
      sku: Value(sku),
      nombre: Value(nombre),
      nombreBusqueda: Value(nombreBusqueda),
      descripcion: descripcion == null && nullToAbsent
          ? const Value.absent()
          : Value(descripcion),
      categoriaUuid: categoriaUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(categoriaUuid),
      unidadMedida: Value(unidadMedida),
      precioCompra: Value(precioCompra),
      precioVenta: Value(precioVenta),
      tasaIva: Value(tasaIva),
      stockActual: Value(stockActual),
      stockMinimo: Value(stockMinimo),
      stockMaximo: stockMaximo == null && nullToAbsent
          ? const Value.absent()
          : Value(stockMaximo),
      imagenUrl: imagenUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(imagenUrl),
      imagenLocal: imagenLocal == null && nullToAbsent
          ? const Value.absent()
          : Value(imagenLocal),
      ubicacion: ubicacion == null && nullToAbsent
          ? const Value.absent()
          : Value(ubicacion),
      activo: Value(activo),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Producto.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Producto(
      uuid: serializer.fromJson<String>(json['uuid']),
      sku: serializer.fromJson<String>(json['sku']),
      nombre: serializer.fromJson<String>(json['nombre']),
      nombreBusqueda: serializer.fromJson<String>(json['nombreBusqueda']),
      descripcion: serializer.fromJson<String?>(json['descripcion']),
      categoriaUuid: serializer.fromJson<String?>(json['categoriaUuid']),
      unidadMedida: serializer.fromJson<String>(json['unidadMedida']),
      precioCompra: serializer.fromJson<int>(json['precioCompra']),
      precioVenta: serializer.fromJson<int>(json['precioVenta']),
      tasaIva: serializer.fromJson<int>(json['tasaIva']),
      stockActual: serializer.fromJson<int>(json['stockActual']),
      stockMinimo: serializer.fromJson<int>(json['stockMinimo']),
      stockMaximo: serializer.fromJson<int?>(json['stockMaximo']),
      imagenUrl: serializer.fromJson<String?>(json['imagenUrl']),
      imagenLocal: serializer.fromJson<String?>(json['imagenLocal']),
      ubicacion: serializer.fromJson<String?>(json['ubicacion']),
      activo: serializer.fromJson<bool>(json['activo']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String>(uuid),
      'sku': serializer.toJson<String>(sku),
      'nombre': serializer.toJson<String>(nombre),
      'nombreBusqueda': serializer.toJson<String>(nombreBusqueda),
      'descripcion': serializer.toJson<String?>(descripcion),
      'categoriaUuid': serializer.toJson<String?>(categoriaUuid),
      'unidadMedida': serializer.toJson<String>(unidadMedida),
      'precioCompra': serializer.toJson<int>(precioCompra),
      'precioVenta': serializer.toJson<int>(precioVenta),
      'tasaIva': serializer.toJson<int>(tasaIva),
      'stockActual': serializer.toJson<int>(stockActual),
      'stockMinimo': serializer.toJson<int>(stockMinimo),
      'stockMaximo': serializer.toJson<int?>(stockMaximo),
      'imagenUrl': serializer.toJson<String?>(imagenUrl),
      'imagenLocal': serializer.toJson<String?>(imagenLocal),
      'ubicacion': serializer.toJson<String?>(ubicacion),
      'activo': serializer.toJson<bool>(activo),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Producto copyWith({
    String? uuid,
    String? sku,
    String? nombre,
    String? nombreBusqueda,
    Value<String?> descripcion = const Value.absent(),
    Value<String?> categoriaUuid = const Value.absent(),
    String? unidadMedida,
    int? precioCompra,
    int? precioVenta,
    int? tasaIva,
    int? stockActual,
    int? stockMinimo,
    Value<int?> stockMaximo = const Value.absent(),
    Value<String?> imagenUrl = const Value.absent(),
    Value<String?> imagenLocal = const Value.absent(),
    Value<String?> ubicacion = const Value.absent(),
    bool? activo,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Producto(
    uuid: uuid ?? this.uuid,
    sku: sku ?? this.sku,
    nombre: nombre ?? this.nombre,
    nombreBusqueda: nombreBusqueda ?? this.nombreBusqueda,
    descripcion: descripcion.present ? descripcion.value : this.descripcion,
    categoriaUuid: categoriaUuid.present
        ? categoriaUuid.value
        : this.categoriaUuid,
    unidadMedida: unidadMedida ?? this.unidadMedida,
    precioCompra: precioCompra ?? this.precioCompra,
    precioVenta: precioVenta ?? this.precioVenta,
    tasaIva: tasaIva ?? this.tasaIva,
    stockActual: stockActual ?? this.stockActual,
    stockMinimo: stockMinimo ?? this.stockMinimo,
    stockMaximo: stockMaximo.present ? stockMaximo.value : this.stockMaximo,
    imagenUrl: imagenUrl.present ? imagenUrl.value : this.imagenUrl,
    imagenLocal: imagenLocal.present ? imagenLocal.value : this.imagenLocal,
    ubicacion: ubicacion.present ? ubicacion.value : this.ubicacion,
    activo: activo ?? this.activo,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Producto copyWithCompanion(ProductosCompanion data) {
    return Producto(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      sku: data.sku.present ? data.sku.value : this.sku,
      nombre: data.nombre.present ? data.nombre.value : this.nombre,
      nombreBusqueda: data.nombreBusqueda.present
          ? data.nombreBusqueda.value
          : this.nombreBusqueda,
      descripcion: data.descripcion.present
          ? data.descripcion.value
          : this.descripcion,
      categoriaUuid: data.categoriaUuid.present
          ? data.categoriaUuid.value
          : this.categoriaUuid,
      unidadMedida: data.unidadMedida.present
          ? data.unidadMedida.value
          : this.unidadMedida,
      precioCompra: data.precioCompra.present
          ? data.precioCompra.value
          : this.precioCompra,
      precioVenta: data.precioVenta.present
          ? data.precioVenta.value
          : this.precioVenta,
      tasaIva: data.tasaIva.present ? data.tasaIva.value : this.tasaIva,
      stockActual: data.stockActual.present
          ? data.stockActual.value
          : this.stockActual,
      stockMinimo: data.stockMinimo.present
          ? data.stockMinimo.value
          : this.stockMinimo,
      stockMaximo: data.stockMaximo.present
          ? data.stockMaximo.value
          : this.stockMaximo,
      imagenUrl: data.imagenUrl.present ? data.imagenUrl.value : this.imagenUrl,
      imagenLocal: data.imagenLocal.present
          ? data.imagenLocal.value
          : this.imagenLocal,
      ubicacion: data.ubicacion.present ? data.ubicacion.value : this.ubicacion,
      activo: data.activo.present ? data.activo.value : this.activo,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Producto(')
          ..write('uuid: $uuid, ')
          ..write('sku: $sku, ')
          ..write('nombre: $nombre, ')
          ..write('nombreBusqueda: $nombreBusqueda, ')
          ..write('descripcion: $descripcion, ')
          ..write('categoriaUuid: $categoriaUuid, ')
          ..write('unidadMedida: $unidadMedida, ')
          ..write('precioCompra: $precioCompra, ')
          ..write('precioVenta: $precioVenta, ')
          ..write('tasaIva: $tasaIva, ')
          ..write('stockActual: $stockActual, ')
          ..write('stockMinimo: $stockMinimo, ')
          ..write('stockMaximo: $stockMaximo, ')
          ..write('imagenUrl: $imagenUrl, ')
          ..write('imagenLocal: $imagenLocal, ')
          ..write('ubicacion: $ubicacion, ')
          ..write('activo: $activo, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    sku,
    nombre,
    nombreBusqueda,
    descripcion,
    categoriaUuid,
    unidadMedida,
    precioCompra,
    precioVenta,
    tasaIva,
    stockActual,
    stockMinimo,
    stockMaximo,
    imagenUrl,
    imagenLocal,
    ubicacion,
    activo,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Producto &&
          other.uuid == this.uuid &&
          other.sku == this.sku &&
          other.nombre == this.nombre &&
          other.nombreBusqueda == this.nombreBusqueda &&
          other.descripcion == this.descripcion &&
          other.categoriaUuid == this.categoriaUuid &&
          other.unidadMedida == this.unidadMedida &&
          other.precioCompra == this.precioCompra &&
          other.precioVenta == this.precioVenta &&
          other.tasaIva == this.tasaIva &&
          other.stockActual == this.stockActual &&
          other.stockMinimo == this.stockMinimo &&
          other.stockMaximo == this.stockMaximo &&
          other.imagenUrl == this.imagenUrl &&
          other.imagenLocal == this.imagenLocal &&
          other.ubicacion == this.ubicacion &&
          other.activo == this.activo &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class ProductosCompanion extends UpdateCompanion<Producto> {
  final Value<String> uuid;
  final Value<String> sku;
  final Value<String> nombre;
  final Value<String> nombreBusqueda;
  final Value<String?> descripcion;
  final Value<String?> categoriaUuid;
  final Value<String> unidadMedida;
  final Value<int> precioCompra;
  final Value<int> precioVenta;
  final Value<int> tasaIva;
  final Value<int> stockActual;
  final Value<int> stockMinimo;
  final Value<int?> stockMaximo;
  final Value<String?> imagenUrl;
  final Value<String?> imagenLocal;
  final Value<String?> ubicacion;
  final Value<bool> activo;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const ProductosCompanion({
    this.uuid = const Value.absent(),
    this.sku = const Value.absent(),
    this.nombre = const Value.absent(),
    this.nombreBusqueda = const Value.absent(),
    this.descripcion = const Value.absent(),
    this.categoriaUuid = const Value.absent(),
    this.unidadMedida = const Value.absent(),
    this.precioCompra = const Value.absent(),
    this.precioVenta = const Value.absent(),
    this.tasaIva = const Value.absent(),
    this.stockActual = const Value.absent(),
    this.stockMinimo = const Value.absent(),
    this.stockMaximo = const Value.absent(),
    this.imagenUrl = const Value.absent(),
    this.imagenLocal = const Value.absent(),
    this.ubicacion = const Value.absent(),
    this.activo = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductosCompanion.insert({
    required String uuid,
    required String sku,
    required String nombre,
    this.nombreBusqueda = const Value.absent(),
    this.descripcion = const Value.absent(),
    this.categoriaUuid = const Value.absent(),
    this.unidadMedida = const Value.absent(),
    this.precioCompra = const Value.absent(),
    this.precioVenta = const Value.absent(),
    this.tasaIva = const Value.absent(),
    this.stockActual = const Value.absent(),
    this.stockMinimo = const Value.absent(),
    this.stockMaximo = const Value.absent(),
    this.imagenUrl = const Value.absent(),
    this.imagenLocal = const Value.absent(),
    this.ubicacion = const Value.absent(),
    this.activo = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       sku = Value(sku),
       nombre = Value(nombre);
  static Insertable<Producto> custom({
    Expression<String>? uuid,
    Expression<String>? sku,
    Expression<String>? nombre,
    Expression<String>? nombreBusqueda,
    Expression<String>? descripcion,
    Expression<String>? categoriaUuid,
    Expression<String>? unidadMedida,
    Expression<int>? precioCompra,
    Expression<int>? precioVenta,
    Expression<int>? tasaIva,
    Expression<int>? stockActual,
    Expression<int>? stockMinimo,
    Expression<int>? stockMaximo,
    Expression<String>? imagenUrl,
    Expression<String>? imagenLocal,
    Expression<String>? ubicacion,
    Expression<bool>? activo,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (sku != null) 'sku': sku,
      if (nombre != null) 'nombre': nombre,
      if (nombreBusqueda != null) 'nombre_busqueda': nombreBusqueda,
      if (descripcion != null) 'descripcion': descripcion,
      if (categoriaUuid != null) 'categoria_uuid': categoriaUuid,
      if (unidadMedida != null) 'unidad_medida': unidadMedida,
      if (precioCompra != null) 'precio_compra': precioCompra,
      if (precioVenta != null) 'precio_venta': precioVenta,
      if (tasaIva != null) 'tasa_iva': tasaIva,
      if (stockActual != null) 'stock_actual': stockActual,
      if (stockMinimo != null) 'stock_minimo': stockMinimo,
      if (stockMaximo != null) 'stock_maximo': stockMaximo,
      if (imagenUrl != null) 'imagen_url': imagenUrl,
      if (imagenLocal != null) 'imagen_local': imagenLocal,
      if (ubicacion != null) 'ubicacion': ubicacion,
      if (activo != null) 'activo': activo,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductosCompanion copyWith({
    Value<String>? uuid,
    Value<String>? sku,
    Value<String>? nombre,
    Value<String>? nombreBusqueda,
    Value<String?>? descripcion,
    Value<String?>? categoriaUuid,
    Value<String>? unidadMedida,
    Value<int>? precioCompra,
    Value<int>? precioVenta,
    Value<int>? tasaIva,
    Value<int>? stockActual,
    Value<int>? stockMinimo,
    Value<int?>? stockMaximo,
    Value<String?>? imagenUrl,
    Value<String?>? imagenLocal,
    Value<String?>? ubicacion,
    Value<bool>? activo,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return ProductosCompanion(
      uuid: uuid ?? this.uuid,
      sku: sku ?? this.sku,
      nombre: nombre ?? this.nombre,
      nombreBusqueda: nombreBusqueda ?? this.nombreBusqueda,
      descripcion: descripcion ?? this.descripcion,
      categoriaUuid: categoriaUuid ?? this.categoriaUuid,
      unidadMedida: unidadMedida ?? this.unidadMedida,
      precioCompra: precioCompra ?? this.precioCompra,
      precioVenta: precioVenta ?? this.precioVenta,
      tasaIva: tasaIva ?? this.tasaIva,
      stockActual: stockActual ?? this.stockActual,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      stockMaximo: stockMaximo ?? this.stockMaximo,
      imagenUrl: imagenUrl ?? this.imagenUrl,
      imagenLocal: imagenLocal ?? this.imagenLocal,
      ubicacion: ubicacion ?? this.ubicacion,
      activo: activo ?? this.activo,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (sku.present) {
      map['sku'] = Variable<String>(sku.value);
    }
    if (nombre.present) {
      map['nombre'] = Variable<String>(nombre.value);
    }
    if (nombreBusqueda.present) {
      map['nombre_busqueda'] = Variable<String>(nombreBusqueda.value);
    }
    if (descripcion.present) {
      map['descripcion'] = Variable<String>(descripcion.value);
    }
    if (categoriaUuid.present) {
      map['categoria_uuid'] = Variable<String>(categoriaUuid.value);
    }
    if (unidadMedida.present) {
      map['unidad_medida'] = Variable<String>(unidadMedida.value);
    }
    if (precioCompra.present) {
      map['precio_compra'] = Variable<int>(precioCompra.value);
    }
    if (precioVenta.present) {
      map['precio_venta'] = Variable<int>(precioVenta.value);
    }
    if (tasaIva.present) {
      map['tasa_iva'] = Variable<int>(tasaIva.value);
    }
    if (stockActual.present) {
      map['stock_actual'] = Variable<int>(stockActual.value);
    }
    if (stockMinimo.present) {
      map['stock_minimo'] = Variable<int>(stockMinimo.value);
    }
    if (stockMaximo.present) {
      map['stock_maximo'] = Variable<int>(stockMaximo.value);
    }
    if (imagenUrl.present) {
      map['imagen_url'] = Variable<String>(imagenUrl.value);
    }
    if (imagenLocal.present) {
      map['imagen_local'] = Variable<String>(imagenLocal.value);
    }
    if (ubicacion.present) {
      map['ubicacion'] = Variable<String>(ubicacion.value);
    }
    if (activo.present) {
      map['activo'] = Variable<bool>(activo.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductosCompanion(')
          ..write('uuid: $uuid, ')
          ..write('sku: $sku, ')
          ..write('nombre: $nombre, ')
          ..write('nombreBusqueda: $nombreBusqueda, ')
          ..write('descripcion: $descripcion, ')
          ..write('categoriaUuid: $categoriaUuid, ')
          ..write('unidadMedida: $unidadMedida, ')
          ..write('precioCompra: $precioCompra, ')
          ..write('precioVenta: $precioVenta, ')
          ..write('tasaIva: $tasaIva, ')
          ..write('stockActual: $stockActual, ')
          ..write('stockMinimo: $stockMinimo, ')
          ..write('stockMaximo: $stockMaximo, ')
          ..write('imagenUrl: $imagenUrl, ')
          ..write('imagenLocal: $imagenLocal, ')
          ..write('ubicacion: $ubicacion, ')
          ..write('activo: $activo, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProductoCodigosTable extends ProductoCodigos
    with TableInfo<$ProductoCodigosTable, ProductoCodigo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductoCodigosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productoUuidMeta = const VerificationMeta(
    'productoUuid',
  );
  @override
  late final GeneratedColumn<String> productoUuid = GeneratedColumn<String>(
    'producto_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codigoMeta = const VerificationMeta('codigo');
  @override
  late final GeneratedColumn<String> codigo = GeneratedColumn<String>(
    'codigo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('INTERNO'),
  );
  static const VerificationMeta _esPrincipalMeta = const VerificationMeta(
    'esPrincipal',
  );
  @override
  late final GeneratedColumn<bool> esPrincipal = GeneratedColumn<bool>(
    'es_principal',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("es_principal" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _factorMeta = const VerificationMeta('factor');
  @override
  late final GeneratedColumn<int> factor = GeneratedColumn<int>(
    'factor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1000),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    productoUuid,
    codigo,
    tipo,
    esPrincipal,
    factor,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'producto_codigos';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProductoCodigo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('producto_uuid')) {
      context.handle(
        _productoUuidMeta,
        productoUuid.isAcceptableOrUnknown(
          data['producto_uuid']!,
          _productoUuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productoUuidMeta);
    }
    if (data.containsKey('codigo')) {
      context.handle(
        _codigoMeta,
        codigo.isAcceptableOrUnknown(data['codigo']!, _codigoMeta),
      );
    } else if (isInserting) {
      context.missing(_codigoMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    }
    if (data.containsKey('es_principal')) {
      context.handle(
        _esPrincipalMeta,
        esPrincipal.isAcceptableOrUnknown(
          data['es_principal']!,
          _esPrincipalMeta,
        ),
      );
    }
    if (data.containsKey('factor')) {
      context.handle(
        _factorMeta,
        factor.isAcceptableOrUnknown(data['factor']!, _factorMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  ProductoCodigo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductoCodigo(
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      productoUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}producto_uuid'],
      )!,
      codigo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codigo'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      esPrincipal: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}es_principal'],
      )!,
      factor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}factor'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $ProductoCodigosTable createAlias(String alias) {
    return $ProductoCodigosTable(attachedDatabase, alias);
  }
}

class ProductoCodigo extends DataClass implements Insertable<ProductoCodigo> {
  final String uuid;
  final String productoUuid;
  final String codigo;
  final String tipo;
  final bool esPrincipal;

  /// Unidades que representa el código: la caja de 12 lleva `12000` (12,000).
  final int factor;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const ProductoCodigo({
    required this.uuid,
    required this.productoUuid,
    required this.codigo,
    required this.tipo,
    required this.esPrincipal,
    required this.factor,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid'] = Variable<String>(uuid);
    map['producto_uuid'] = Variable<String>(productoUuid);
    map['codigo'] = Variable<String>(codigo);
    map['tipo'] = Variable<String>(tipo);
    map['es_principal'] = Variable<bool>(esPrincipal);
    map['factor'] = Variable<int>(factor);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  ProductoCodigosCompanion toCompanion(bool nullToAbsent) {
    return ProductoCodigosCompanion(
      uuid: Value(uuid),
      productoUuid: Value(productoUuid),
      codigo: Value(codigo),
      tipo: Value(tipo),
      esPrincipal: Value(esPrincipal),
      factor: Value(factor),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory ProductoCodigo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductoCodigo(
      uuid: serializer.fromJson<String>(json['uuid']),
      productoUuid: serializer.fromJson<String>(json['productoUuid']),
      codigo: serializer.fromJson<String>(json['codigo']),
      tipo: serializer.fromJson<String>(json['tipo']),
      esPrincipal: serializer.fromJson<bool>(json['esPrincipal']),
      factor: serializer.fromJson<int>(json['factor']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String>(uuid),
      'productoUuid': serializer.toJson<String>(productoUuid),
      'codigo': serializer.toJson<String>(codigo),
      'tipo': serializer.toJson<String>(tipo),
      'esPrincipal': serializer.toJson<bool>(esPrincipal),
      'factor': serializer.toJson<int>(factor),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  ProductoCodigo copyWith({
    String? uuid,
    String? productoUuid,
    String? codigo,
    String? tipo,
    bool? esPrincipal,
    int? factor,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => ProductoCodigo(
    uuid: uuid ?? this.uuid,
    productoUuid: productoUuid ?? this.productoUuid,
    codigo: codigo ?? this.codigo,
    tipo: tipo ?? this.tipo,
    esPrincipal: esPrincipal ?? this.esPrincipal,
    factor: factor ?? this.factor,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  ProductoCodigo copyWithCompanion(ProductoCodigosCompanion data) {
    return ProductoCodigo(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      productoUuid: data.productoUuid.present
          ? data.productoUuid.value
          : this.productoUuid,
      codigo: data.codigo.present ? data.codigo.value : this.codigo,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      esPrincipal: data.esPrincipal.present
          ? data.esPrincipal.value
          : this.esPrincipal,
      factor: data.factor.present ? data.factor.value : this.factor,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductoCodigo(')
          ..write('uuid: $uuid, ')
          ..write('productoUuid: $productoUuid, ')
          ..write('codigo: $codigo, ')
          ..write('tipo: $tipo, ')
          ..write('esPrincipal: $esPrincipal, ')
          ..write('factor: $factor, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    productoUuid,
    codigo,
    tipo,
    esPrincipal,
    factor,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductoCodigo &&
          other.uuid == this.uuid &&
          other.productoUuid == this.productoUuid &&
          other.codigo == this.codigo &&
          other.tipo == this.tipo &&
          other.esPrincipal == this.esPrincipal &&
          other.factor == this.factor &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class ProductoCodigosCompanion extends UpdateCompanion<ProductoCodigo> {
  final Value<String> uuid;
  final Value<String> productoUuid;
  final Value<String> codigo;
  final Value<String> tipo;
  final Value<bool> esPrincipal;
  final Value<int> factor;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const ProductoCodigosCompanion({
    this.uuid = const Value.absent(),
    this.productoUuid = const Value.absent(),
    this.codigo = const Value.absent(),
    this.tipo = const Value.absent(),
    this.esPrincipal = const Value.absent(),
    this.factor = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductoCodigosCompanion.insert({
    required String uuid,
    required String productoUuid,
    required String codigo,
    this.tipo = const Value.absent(),
    this.esPrincipal = const Value.absent(),
    this.factor = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       productoUuid = Value(productoUuid),
       codigo = Value(codigo);
  static Insertable<ProductoCodigo> custom({
    Expression<String>? uuid,
    Expression<String>? productoUuid,
    Expression<String>? codigo,
    Expression<String>? tipo,
    Expression<bool>? esPrincipal,
    Expression<int>? factor,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (productoUuid != null) 'producto_uuid': productoUuid,
      if (codigo != null) 'codigo': codigo,
      if (tipo != null) 'tipo': tipo,
      if (esPrincipal != null) 'es_principal': esPrincipal,
      if (factor != null) 'factor': factor,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductoCodigosCompanion copyWith({
    Value<String>? uuid,
    Value<String>? productoUuid,
    Value<String>? codigo,
    Value<String>? tipo,
    Value<bool>? esPrincipal,
    Value<int>? factor,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return ProductoCodigosCompanion(
      uuid: uuid ?? this.uuid,
      productoUuid: productoUuid ?? this.productoUuid,
      codigo: codigo ?? this.codigo,
      tipo: tipo ?? this.tipo,
      esPrincipal: esPrincipal ?? this.esPrincipal,
      factor: factor ?? this.factor,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (productoUuid.present) {
      map['producto_uuid'] = Variable<String>(productoUuid.value);
    }
    if (codigo.present) {
      map['codigo'] = Variable<String>(codigo.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (esPrincipal.present) {
      map['es_principal'] = Variable<bool>(esPrincipal.value);
    }
    if (factor.present) {
      map['factor'] = Variable<int>(factor.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductoCodigosCompanion(')
          ..write('uuid: $uuid, ')
          ..write('productoUuid: $productoUuid, ')
          ..write('codigo: $codigo, ')
          ..write('tipo: $tipo, ')
          ..write('esPrincipal: $esPrincipal, ')
          ..write('factor: $factor, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VentasTable extends Ventas with TableInfo<$VentasTable, Venta> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VentasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _numeroMeta = const VerificationMeta('numero');
  @override
  late final GeneratedColumn<String> numero = GeneratedColumn<String>(
    'numero',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usuarioUuidMeta = const VerificationMeta(
    'usuarioUuid',
  );
  @override
  late final GeneratedColumn<String> usuarioUuid = GeneratedColumn<String>(
    'usuario_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dispositivoUuidMeta = const VerificationMeta(
    'dispositivoUuid',
  );
  @override
  late final GeneratedColumn<String> dispositivoUuid = GeneratedColumn<String>(
    'dispositivo_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clienteNombreMeta = const VerificationMeta(
    'clienteNombre',
  );
  @override
  late final GeneratedColumn<String> clienteNombre = GeneratedColumn<String>(
    'cliente_nombre',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clienteDocumentoMeta = const VerificationMeta(
    'clienteDocumento',
  );
  @override
  late final GeneratedColumn<String> clienteDocumento = GeneratedColumn<String>(
    'cliente_documento',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _subtotalMeta = const VerificationMeta(
    'subtotal',
  );
  @override
  late final GeneratedColumn<int> subtotal = GeneratedColumn<int>(
    'subtotal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _descuentoTotalMeta = const VerificationMeta(
    'descuentoTotal',
  );
  @override
  late final GeneratedColumn<int> descuentoTotal = GeneratedColumn<int>(
    'descuento_total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _impuestoTotalMeta = const VerificationMeta(
    'impuestoTotal',
  );
  @override
  late final GeneratedColumn<int> impuestoTotal = GeneratedColumn<int>(
    'impuesto_total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<int> total = GeneratedColumn<int>(
    'total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _costoTotalMeta = const VerificationMeta(
    'costoTotal',
  );
  @override
  late final GeneratedColumn<int> costoTotal = GeneratedColumn<int>(
    'costo_total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _metodoPagoMeta = const VerificationMeta(
    'metodoPago',
  );
  @override
  late final GeneratedColumn<String> metodoPago = GeneratedColumn<String>(
    'metodo_pago',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('EFECTIVO'),
  );
  static const VerificationMeta _montoRecibidoMeta = const VerificationMeta(
    'montoRecibido',
  );
  @override
  late final GeneratedColumn<int> montoRecibido = GeneratedColumn<int>(
    'monto_recibido',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cambioMeta = const VerificationMeta('cambio');
  @override
  late final GeneratedColumn<int> cambio = GeneratedColumn<int>(
    'cambio',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _estadoMeta = const VerificationMeta('estado');
  @override
  late final GeneratedColumn<String> estado = GeneratedColumn<String>(
    'estado',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('COMPLETADA'),
  );
  static const VerificationMeta _anulaAVentaUuidMeta = const VerificationMeta(
    'anulaAVentaUuid',
  );
  @override
  late final GeneratedColumn<String> anulaAVentaUuid = GeneratedColumn<String>(
    'anula_a_venta_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _motivoAnulacionMeta = const VerificationMeta(
    'motivoAnulacion',
  );
  @override
  late final GeneratedColumn<String> motivoAnulacion = GeneratedColumn<String>(
    'motivo_anulacion',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notasMeta = const VerificationMeta('notas');
  @override
  late final GeneratedColumn<String> notas = GeneratedColumn<String>(
    'notas',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<DateTime> fecha = GeneratedColumn<DateTime>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaLocalMeta = const VerificationMeta(
    'fechaLocal',
  );
  @override
  late final GeneratedColumn<String> fechaLocal = GeneratedColumn<String>(
    'fecha_local',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _creadaOfflineMeta = const VerificationMeta(
    'creadaOffline',
  );
  @override
  late final GeneratedColumn<bool> creadaOffline = GeneratedColumn<bool>(
    'creada_offline',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("creada_offline" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _sincronizadaEnMeta = const VerificationMeta(
    'sincronizadaEn',
  );
  @override
  late final GeneratedColumn<DateTime> sincronizadaEn =
      GeneratedColumn<DateTime>(
        'sincronizada_en',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    numero,
    usuarioUuid,
    dispositivoUuid,
    clienteNombre,
    clienteDocumento,
    subtotal,
    descuentoTotal,
    impuestoTotal,
    total,
    costoTotal,
    metodoPago,
    montoRecibido,
    cambio,
    estado,
    anulaAVentaUuid,
    motivoAnulacion,
    notas,
    fecha,
    fechaLocal,
    creadaOffline,
    sincronizadaEn,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ventas';
  @override
  VerificationContext validateIntegrity(
    Insertable<Venta> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('numero')) {
      context.handle(
        _numeroMeta,
        numero.isAcceptableOrUnknown(data['numero']!, _numeroMeta),
      );
    } else if (isInserting) {
      context.missing(_numeroMeta);
    }
    if (data.containsKey('usuario_uuid')) {
      context.handle(
        _usuarioUuidMeta,
        usuarioUuid.isAcceptableOrUnknown(
          data['usuario_uuid']!,
          _usuarioUuidMeta,
        ),
      );
    }
    if (data.containsKey('dispositivo_uuid')) {
      context.handle(
        _dispositivoUuidMeta,
        dispositivoUuid.isAcceptableOrUnknown(
          data['dispositivo_uuid']!,
          _dispositivoUuidMeta,
        ),
      );
    }
    if (data.containsKey('cliente_nombre')) {
      context.handle(
        _clienteNombreMeta,
        clienteNombre.isAcceptableOrUnknown(
          data['cliente_nombre']!,
          _clienteNombreMeta,
        ),
      );
    }
    if (data.containsKey('cliente_documento')) {
      context.handle(
        _clienteDocumentoMeta,
        clienteDocumento.isAcceptableOrUnknown(
          data['cliente_documento']!,
          _clienteDocumentoMeta,
        ),
      );
    }
    if (data.containsKey('subtotal')) {
      context.handle(
        _subtotalMeta,
        subtotal.isAcceptableOrUnknown(data['subtotal']!, _subtotalMeta),
      );
    }
    if (data.containsKey('descuento_total')) {
      context.handle(
        _descuentoTotalMeta,
        descuentoTotal.isAcceptableOrUnknown(
          data['descuento_total']!,
          _descuentoTotalMeta,
        ),
      );
    }
    if (data.containsKey('impuesto_total')) {
      context.handle(
        _impuestoTotalMeta,
        impuestoTotal.isAcceptableOrUnknown(
          data['impuesto_total']!,
          _impuestoTotalMeta,
        ),
      );
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    }
    if (data.containsKey('costo_total')) {
      context.handle(
        _costoTotalMeta,
        costoTotal.isAcceptableOrUnknown(data['costo_total']!, _costoTotalMeta),
      );
    }
    if (data.containsKey('metodo_pago')) {
      context.handle(
        _metodoPagoMeta,
        metodoPago.isAcceptableOrUnknown(data['metodo_pago']!, _metodoPagoMeta),
      );
    }
    if (data.containsKey('monto_recibido')) {
      context.handle(
        _montoRecibidoMeta,
        montoRecibido.isAcceptableOrUnknown(
          data['monto_recibido']!,
          _montoRecibidoMeta,
        ),
      );
    }
    if (data.containsKey('cambio')) {
      context.handle(
        _cambioMeta,
        cambio.isAcceptableOrUnknown(data['cambio']!, _cambioMeta),
      );
    }
    if (data.containsKey('estado')) {
      context.handle(
        _estadoMeta,
        estado.isAcceptableOrUnknown(data['estado']!, _estadoMeta),
      );
    }
    if (data.containsKey('anula_a_venta_uuid')) {
      context.handle(
        _anulaAVentaUuidMeta,
        anulaAVentaUuid.isAcceptableOrUnknown(
          data['anula_a_venta_uuid']!,
          _anulaAVentaUuidMeta,
        ),
      );
    }
    if (data.containsKey('motivo_anulacion')) {
      context.handle(
        _motivoAnulacionMeta,
        motivoAnulacion.isAcceptableOrUnknown(
          data['motivo_anulacion']!,
          _motivoAnulacionMeta,
        ),
      );
    }
    if (data.containsKey('notas')) {
      context.handle(
        _notasMeta,
        notas.isAcceptableOrUnknown(data['notas']!, _notasMeta),
      );
    }
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaMeta);
    }
    if (data.containsKey('fecha_local')) {
      context.handle(
        _fechaLocalMeta,
        fechaLocal.isAcceptableOrUnknown(data['fecha_local']!, _fechaLocalMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaLocalMeta);
    }
    if (data.containsKey('creada_offline')) {
      context.handle(
        _creadaOfflineMeta,
        creadaOffline.isAcceptableOrUnknown(
          data['creada_offline']!,
          _creadaOfflineMeta,
        ),
      );
    }
    if (data.containsKey('sincronizada_en')) {
      context.handle(
        _sincronizadaEnMeta,
        sincronizadaEn.isAcceptableOrUnknown(
          data['sincronizada_en']!,
          _sincronizadaEnMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  Venta map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Venta(
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      numero: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}numero'],
      )!,
      usuarioUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}usuario_uuid'],
      ),
      dispositivoUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dispositivo_uuid'],
      ),
      clienteNombre: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cliente_nombre'],
      ),
      clienteDocumento: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cliente_documento'],
      ),
      subtotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}subtotal'],
      )!,
      descuentoTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}descuento_total'],
      )!,
      impuestoTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}impuesto_total'],
      )!,
      total: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total'],
      )!,
      costoTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}costo_total'],
      )!,
      metodoPago: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metodo_pago'],
      )!,
      montoRecibido: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}monto_recibido'],
      ),
      cambio: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cambio'],
      ),
      estado: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}estado'],
      )!,
      anulaAVentaUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anula_a_venta_uuid'],
      ),
      motivoAnulacion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}motivo_anulacion'],
      ),
      notas: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notas'],
      ),
      fecha: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha'],
      )!,
      fechaLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fecha_local'],
      )!,
      creadaOffline: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}creada_offline'],
      )!,
      sincronizadaEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sincronizada_en'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  $VentasTable createAlias(String alias) {
    return $VentasTable(attachedDatabase, alias);
  }
}

class Venta extends DataClass implements Insertable<Venta> {
  final String uuid;
  final String numero;
  final String? usuarioUuid;
  final String? dispositivoUuid;
  final String? clienteNombre;
  final String? clienteDocumento;
  final int subtotal;
  final int descuentoTotal;
  final int impuestoTotal;
  final int total;
  final int costoTotal;
  final String metodoPago;
  final int? montoRecibido;
  final int? cambio;
  final String estado;
  final String? anulaAVentaUuid;
  final String? motivoAnulacion;
  final String? notas;
  final DateTime fecha;
  final String fechaLocal;
  final bool creadaOffline;

  /// `null` mientras la venta no haya llegado al servidor. Es lo que cuenta el
  /// chip «N pendientes».
  final DateTime? sincronizadaEn;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  const Venta({
    required this.uuid,
    required this.numero,
    this.usuarioUuid,
    this.dispositivoUuid,
    this.clienteNombre,
    this.clienteDocumento,
    required this.subtotal,
    required this.descuentoTotal,
    required this.impuestoTotal,
    required this.total,
    required this.costoTotal,
    required this.metodoPago,
    this.montoRecibido,
    this.cambio,
    required this.estado,
    this.anulaAVentaUuid,
    this.motivoAnulacion,
    this.notas,
    required this.fecha,
    required this.fechaLocal,
    required this.creadaOffline,
    this.sincronizadaEn,
    required this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid'] = Variable<String>(uuid);
    map['numero'] = Variable<String>(numero);
    if (!nullToAbsent || usuarioUuid != null) {
      map['usuario_uuid'] = Variable<String>(usuarioUuid);
    }
    if (!nullToAbsent || dispositivoUuid != null) {
      map['dispositivo_uuid'] = Variable<String>(dispositivoUuid);
    }
    if (!nullToAbsent || clienteNombre != null) {
      map['cliente_nombre'] = Variable<String>(clienteNombre);
    }
    if (!nullToAbsent || clienteDocumento != null) {
      map['cliente_documento'] = Variable<String>(clienteDocumento);
    }
    map['subtotal'] = Variable<int>(subtotal);
    map['descuento_total'] = Variable<int>(descuentoTotal);
    map['impuesto_total'] = Variable<int>(impuestoTotal);
    map['total'] = Variable<int>(total);
    map['costo_total'] = Variable<int>(costoTotal);
    map['metodo_pago'] = Variable<String>(metodoPago);
    if (!nullToAbsent || montoRecibido != null) {
      map['monto_recibido'] = Variable<int>(montoRecibido);
    }
    if (!nullToAbsent || cambio != null) {
      map['cambio'] = Variable<int>(cambio);
    }
    map['estado'] = Variable<String>(estado);
    if (!nullToAbsent || anulaAVentaUuid != null) {
      map['anula_a_venta_uuid'] = Variable<String>(anulaAVentaUuid);
    }
    if (!nullToAbsent || motivoAnulacion != null) {
      map['motivo_anulacion'] = Variable<String>(motivoAnulacion);
    }
    if (!nullToAbsent || notas != null) {
      map['notas'] = Variable<String>(notas);
    }
    map['fecha'] = Variable<DateTime>(fecha);
    map['fecha_local'] = Variable<String>(fechaLocal);
    map['creada_offline'] = Variable<bool>(creadaOffline);
    if (!nullToAbsent || sincronizadaEn != null) {
      map['sincronizada_en'] = Variable<DateTime>(sincronizadaEn);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    return map;
  }

  VentasCompanion toCompanion(bool nullToAbsent) {
    return VentasCompanion(
      uuid: Value(uuid),
      numero: Value(numero),
      usuarioUuid: usuarioUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(usuarioUuid),
      dispositivoUuid: dispositivoUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(dispositivoUuid),
      clienteNombre: clienteNombre == null && nullToAbsent
          ? const Value.absent()
          : Value(clienteNombre),
      clienteDocumento: clienteDocumento == null && nullToAbsent
          ? const Value.absent()
          : Value(clienteDocumento),
      subtotal: Value(subtotal),
      descuentoTotal: Value(descuentoTotal),
      impuestoTotal: Value(impuestoTotal),
      total: Value(total),
      costoTotal: Value(costoTotal),
      metodoPago: Value(metodoPago),
      montoRecibido: montoRecibido == null && nullToAbsent
          ? const Value.absent()
          : Value(montoRecibido),
      cambio: cambio == null && nullToAbsent
          ? const Value.absent()
          : Value(cambio),
      estado: Value(estado),
      anulaAVentaUuid: anulaAVentaUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(anulaAVentaUuid),
      motivoAnulacion: motivoAnulacion == null && nullToAbsent
          ? const Value.absent()
          : Value(motivoAnulacion),
      notas: notas == null && nullToAbsent
          ? const Value.absent()
          : Value(notas),
      fecha: Value(fecha),
      fechaLocal: Value(fechaLocal),
      creadaOffline: Value(creadaOffline),
      sincronizadaEn: sincronizadaEn == null && nullToAbsent
          ? const Value.absent()
          : Value(sincronizadaEn),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Venta.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Venta(
      uuid: serializer.fromJson<String>(json['uuid']),
      numero: serializer.fromJson<String>(json['numero']),
      usuarioUuid: serializer.fromJson<String?>(json['usuarioUuid']),
      dispositivoUuid: serializer.fromJson<String?>(json['dispositivoUuid']),
      clienteNombre: serializer.fromJson<String?>(json['clienteNombre']),
      clienteDocumento: serializer.fromJson<String?>(json['clienteDocumento']),
      subtotal: serializer.fromJson<int>(json['subtotal']),
      descuentoTotal: serializer.fromJson<int>(json['descuentoTotal']),
      impuestoTotal: serializer.fromJson<int>(json['impuestoTotal']),
      total: serializer.fromJson<int>(json['total']),
      costoTotal: serializer.fromJson<int>(json['costoTotal']),
      metodoPago: serializer.fromJson<String>(json['metodoPago']),
      montoRecibido: serializer.fromJson<int?>(json['montoRecibido']),
      cambio: serializer.fromJson<int?>(json['cambio']),
      estado: serializer.fromJson<String>(json['estado']),
      anulaAVentaUuid: serializer.fromJson<String?>(json['anulaAVentaUuid']),
      motivoAnulacion: serializer.fromJson<String?>(json['motivoAnulacion']),
      notas: serializer.fromJson<String?>(json['notas']),
      fecha: serializer.fromJson<DateTime>(json['fecha']),
      fechaLocal: serializer.fromJson<String>(json['fechaLocal']),
      creadaOffline: serializer.fromJson<bool>(json['creadaOffline']),
      sincronizadaEn: serializer.fromJson<DateTime?>(json['sincronizadaEn']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String>(uuid),
      'numero': serializer.toJson<String>(numero),
      'usuarioUuid': serializer.toJson<String?>(usuarioUuid),
      'dispositivoUuid': serializer.toJson<String?>(dispositivoUuid),
      'clienteNombre': serializer.toJson<String?>(clienteNombre),
      'clienteDocumento': serializer.toJson<String?>(clienteDocumento),
      'subtotal': serializer.toJson<int>(subtotal),
      'descuentoTotal': serializer.toJson<int>(descuentoTotal),
      'impuestoTotal': serializer.toJson<int>(impuestoTotal),
      'total': serializer.toJson<int>(total),
      'costoTotal': serializer.toJson<int>(costoTotal),
      'metodoPago': serializer.toJson<String>(metodoPago),
      'montoRecibido': serializer.toJson<int?>(montoRecibido),
      'cambio': serializer.toJson<int?>(cambio),
      'estado': serializer.toJson<String>(estado),
      'anulaAVentaUuid': serializer.toJson<String?>(anulaAVentaUuid),
      'motivoAnulacion': serializer.toJson<String?>(motivoAnulacion),
      'notas': serializer.toJson<String?>(notas),
      'fecha': serializer.toJson<DateTime>(fecha),
      'fechaLocal': serializer.toJson<String>(fechaLocal),
      'creadaOffline': serializer.toJson<bool>(creadaOffline),
      'sincronizadaEn': serializer.toJson<DateTime?>(sincronizadaEn),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  Venta copyWith({
    String? uuid,
    String? numero,
    Value<String?> usuarioUuid = const Value.absent(),
    Value<String?> dispositivoUuid = const Value.absent(),
    Value<String?> clienteNombre = const Value.absent(),
    Value<String?> clienteDocumento = const Value.absent(),
    int? subtotal,
    int? descuentoTotal,
    int? impuestoTotal,
    int? total,
    int? costoTotal,
    String? metodoPago,
    Value<int?> montoRecibido = const Value.absent(),
    Value<int?> cambio = const Value.absent(),
    String? estado,
    Value<String?> anulaAVentaUuid = const Value.absent(),
    Value<String?> motivoAnulacion = const Value.absent(),
    Value<String?> notas = const Value.absent(),
    DateTime? fecha,
    String? fechaLocal,
    bool? creadaOffline,
    Value<DateTime?> sincronizadaEn = const Value.absent(),
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => Venta(
    uuid: uuid ?? this.uuid,
    numero: numero ?? this.numero,
    usuarioUuid: usuarioUuid.present ? usuarioUuid.value : this.usuarioUuid,
    dispositivoUuid: dispositivoUuid.present
        ? dispositivoUuid.value
        : this.dispositivoUuid,
    clienteNombre: clienteNombre.present
        ? clienteNombre.value
        : this.clienteNombre,
    clienteDocumento: clienteDocumento.present
        ? clienteDocumento.value
        : this.clienteDocumento,
    subtotal: subtotal ?? this.subtotal,
    descuentoTotal: descuentoTotal ?? this.descuentoTotal,
    impuestoTotal: impuestoTotal ?? this.impuestoTotal,
    total: total ?? this.total,
    costoTotal: costoTotal ?? this.costoTotal,
    metodoPago: metodoPago ?? this.metodoPago,
    montoRecibido: montoRecibido.present
        ? montoRecibido.value
        : this.montoRecibido,
    cambio: cambio.present ? cambio.value : this.cambio,
    estado: estado ?? this.estado,
    anulaAVentaUuid: anulaAVentaUuid.present
        ? anulaAVentaUuid.value
        : this.anulaAVentaUuid,
    motivoAnulacion: motivoAnulacion.present
        ? motivoAnulacion.value
        : this.motivoAnulacion,
    notas: notas.present ? notas.value : this.notas,
    fecha: fecha ?? this.fecha,
    fechaLocal: fechaLocal ?? this.fechaLocal,
    creadaOffline: creadaOffline ?? this.creadaOffline,
    sincronizadaEn: sincronizadaEn.present
        ? sincronizadaEn.value
        : this.sincronizadaEn,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Venta copyWithCompanion(VentasCompanion data) {
    return Venta(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      numero: data.numero.present ? data.numero.value : this.numero,
      usuarioUuid: data.usuarioUuid.present
          ? data.usuarioUuid.value
          : this.usuarioUuid,
      dispositivoUuid: data.dispositivoUuid.present
          ? data.dispositivoUuid.value
          : this.dispositivoUuid,
      clienteNombre: data.clienteNombre.present
          ? data.clienteNombre.value
          : this.clienteNombre,
      clienteDocumento: data.clienteDocumento.present
          ? data.clienteDocumento.value
          : this.clienteDocumento,
      subtotal: data.subtotal.present ? data.subtotal.value : this.subtotal,
      descuentoTotal: data.descuentoTotal.present
          ? data.descuentoTotal.value
          : this.descuentoTotal,
      impuestoTotal: data.impuestoTotal.present
          ? data.impuestoTotal.value
          : this.impuestoTotal,
      total: data.total.present ? data.total.value : this.total,
      costoTotal: data.costoTotal.present
          ? data.costoTotal.value
          : this.costoTotal,
      metodoPago: data.metodoPago.present
          ? data.metodoPago.value
          : this.metodoPago,
      montoRecibido: data.montoRecibido.present
          ? data.montoRecibido.value
          : this.montoRecibido,
      cambio: data.cambio.present ? data.cambio.value : this.cambio,
      estado: data.estado.present ? data.estado.value : this.estado,
      anulaAVentaUuid: data.anulaAVentaUuid.present
          ? data.anulaAVentaUuid.value
          : this.anulaAVentaUuid,
      motivoAnulacion: data.motivoAnulacion.present
          ? data.motivoAnulacion.value
          : this.motivoAnulacion,
      notas: data.notas.present ? data.notas.value : this.notas,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
      fechaLocal: data.fechaLocal.present
          ? data.fechaLocal.value
          : this.fechaLocal,
      creadaOffline: data.creadaOffline.present
          ? data.creadaOffline.value
          : this.creadaOffline,
      sincronizadaEn: data.sincronizadaEn.present
          ? data.sincronizadaEn.value
          : this.sincronizadaEn,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Venta(')
          ..write('uuid: $uuid, ')
          ..write('numero: $numero, ')
          ..write('usuarioUuid: $usuarioUuid, ')
          ..write('dispositivoUuid: $dispositivoUuid, ')
          ..write('clienteNombre: $clienteNombre, ')
          ..write('clienteDocumento: $clienteDocumento, ')
          ..write('subtotal: $subtotal, ')
          ..write('descuentoTotal: $descuentoTotal, ')
          ..write('impuestoTotal: $impuestoTotal, ')
          ..write('total: $total, ')
          ..write('costoTotal: $costoTotal, ')
          ..write('metodoPago: $metodoPago, ')
          ..write('montoRecibido: $montoRecibido, ')
          ..write('cambio: $cambio, ')
          ..write('estado: $estado, ')
          ..write('anulaAVentaUuid: $anulaAVentaUuid, ')
          ..write('motivoAnulacion: $motivoAnulacion, ')
          ..write('notas: $notas, ')
          ..write('fecha: $fecha, ')
          ..write('fechaLocal: $fechaLocal, ')
          ..write('creadaOffline: $creadaOffline, ')
          ..write('sincronizadaEn: $sincronizadaEn, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    uuid,
    numero,
    usuarioUuid,
    dispositivoUuid,
    clienteNombre,
    clienteDocumento,
    subtotal,
    descuentoTotal,
    impuestoTotal,
    total,
    costoTotal,
    metodoPago,
    montoRecibido,
    cambio,
    estado,
    anulaAVentaUuid,
    motivoAnulacion,
    notas,
    fecha,
    fechaLocal,
    creadaOffline,
    sincronizadaEn,
    updatedAt,
    deletedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Venta &&
          other.uuid == this.uuid &&
          other.numero == this.numero &&
          other.usuarioUuid == this.usuarioUuid &&
          other.dispositivoUuid == this.dispositivoUuid &&
          other.clienteNombre == this.clienteNombre &&
          other.clienteDocumento == this.clienteDocumento &&
          other.subtotal == this.subtotal &&
          other.descuentoTotal == this.descuentoTotal &&
          other.impuestoTotal == this.impuestoTotal &&
          other.total == this.total &&
          other.costoTotal == this.costoTotal &&
          other.metodoPago == this.metodoPago &&
          other.montoRecibido == this.montoRecibido &&
          other.cambio == this.cambio &&
          other.estado == this.estado &&
          other.anulaAVentaUuid == this.anulaAVentaUuid &&
          other.motivoAnulacion == this.motivoAnulacion &&
          other.notas == this.notas &&
          other.fecha == this.fecha &&
          other.fechaLocal == this.fechaLocal &&
          other.creadaOffline == this.creadaOffline &&
          other.sincronizadaEn == this.sincronizadaEn &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class VentasCompanion extends UpdateCompanion<Venta> {
  final Value<String> uuid;
  final Value<String> numero;
  final Value<String?> usuarioUuid;
  final Value<String?> dispositivoUuid;
  final Value<String?> clienteNombre;
  final Value<String?> clienteDocumento;
  final Value<int> subtotal;
  final Value<int> descuentoTotal;
  final Value<int> impuestoTotal;
  final Value<int> total;
  final Value<int> costoTotal;
  final Value<String> metodoPago;
  final Value<int?> montoRecibido;
  final Value<int?> cambio;
  final Value<String> estado;
  final Value<String?> anulaAVentaUuid;
  final Value<String?> motivoAnulacion;
  final Value<String?> notas;
  final Value<DateTime> fecha;
  final Value<String> fechaLocal;
  final Value<bool> creadaOffline;
  final Value<DateTime?> sincronizadaEn;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const VentasCompanion({
    this.uuid = const Value.absent(),
    this.numero = const Value.absent(),
    this.usuarioUuid = const Value.absent(),
    this.dispositivoUuid = const Value.absent(),
    this.clienteNombre = const Value.absent(),
    this.clienteDocumento = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.descuentoTotal = const Value.absent(),
    this.impuestoTotal = const Value.absent(),
    this.total = const Value.absent(),
    this.costoTotal = const Value.absent(),
    this.metodoPago = const Value.absent(),
    this.montoRecibido = const Value.absent(),
    this.cambio = const Value.absent(),
    this.estado = const Value.absent(),
    this.anulaAVentaUuid = const Value.absent(),
    this.motivoAnulacion = const Value.absent(),
    this.notas = const Value.absent(),
    this.fecha = const Value.absent(),
    this.fechaLocal = const Value.absent(),
    this.creadaOffline = const Value.absent(),
    this.sincronizadaEn = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VentasCompanion.insert({
    required String uuid,
    required String numero,
    this.usuarioUuid = const Value.absent(),
    this.dispositivoUuid = const Value.absent(),
    this.clienteNombre = const Value.absent(),
    this.clienteDocumento = const Value.absent(),
    this.subtotal = const Value.absent(),
    this.descuentoTotal = const Value.absent(),
    this.impuestoTotal = const Value.absent(),
    this.total = const Value.absent(),
    this.costoTotal = const Value.absent(),
    this.metodoPago = const Value.absent(),
    this.montoRecibido = const Value.absent(),
    this.cambio = const Value.absent(),
    this.estado = const Value.absent(),
    this.anulaAVentaUuid = const Value.absent(),
    this.motivoAnulacion = const Value.absent(),
    this.notas = const Value.absent(),
    required DateTime fecha,
    required String fechaLocal,
    this.creadaOffline = const Value.absent(),
    this.sincronizadaEn = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       numero = Value(numero),
       fecha = Value(fecha),
       fechaLocal = Value(fechaLocal);
  static Insertable<Venta> custom({
    Expression<String>? uuid,
    Expression<String>? numero,
    Expression<String>? usuarioUuid,
    Expression<String>? dispositivoUuid,
    Expression<String>? clienteNombre,
    Expression<String>? clienteDocumento,
    Expression<int>? subtotal,
    Expression<int>? descuentoTotal,
    Expression<int>? impuestoTotal,
    Expression<int>? total,
    Expression<int>? costoTotal,
    Expression<String>? metodoPago,
    Expression<int>? montoRecibido,
    Expression<int>? cambio,
    Expression<String>? estado,
    Expression<String>? anulaAVentaUuid,
    Expression<String>? motivoAnulacion,
    Expression<String>? notas,
    Expression<DateTime>? fecha,
    Expression<String>? fechaLocal,
    Expression<bool>? creadaOffline,
    Expression<DateTime>? sincronizadaEn,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (numero != null) 'numero': numero,
      if (usuarioUuid != null) 'usuario_uuid': usuarioUuid,
      if (dispositivoUuid != null) 'dispositivo_uuid': dispositivoUuid,
      if (clienteNombre != null) 'cliente_nombre': clienteNombre,
      if (clienteDocumento != null) 'cliente_documento': clienteDocumento,
      if (subtotal != null) 'subtotal': subtotal,
      if (descuentoTotal != null) 'descuento_total': descuentoTotal,
      if (impuestoTotal != null) 'impuesto_total': impuestoTotal,
      if (total != null) 'total': total,
      if (costoTotal != null) 'costo_total': costoTotal,
      if (metodoPago != null) 'metodo_pago': metodoPago,
      if (montoRecibido != null) 'monto_recibido': montoRecibido,
      if (cambio != null) 'cambio': cambio,
      if (estado != null) 'estado': estado,
      if (anulaAVentaUuid != null) 'anula_a_venta_uuid': anulaAVentaUuid,
      if (motivoAnulacion != null) 'motivo_anulacion': motivoAnulacion,
      if (notas != null) 'notas': notas,
      if (fecha != null) 'fecha': fecha,
      if (fechaLocal != null) 'fecha_local': fechaLocal,
      if (creadaOffline != null) 'creada_offline': creadaOffline,
      if (sincronizadaEn != null) 'sincronizada_en': sincronizadaEn,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VentasCompanion copyWith({
    Value<String>? uuid,
    Value<String>? numero,
    Value<String?>? usuarioUuid,
    Value<String?>? dispositivoUuid,
    Value<String?>? clienteNombre,
    Value<String?>? clienteDocumento,
    Value<int>? subtotal,
    Value<int>? descuentoTotal,
    Value<int>? impuestoTotal,
    Value<int>? total,
    Value<int>? costoTotal,
    Value<String>? metodoPago,
    Value<int?>? montoRecibido,
    Value<int?>? cambio,
    Value<String>? estado,
    Value<String?>? anulaAVentaUuid,
    Value<String?>? motivoAnulacion,
    Value<String?>? notas,
    Value<DateTime>? fecha,
    Value<String>? fechaLocal,
    Value<bool>? creadaOffline,
    Value<DateTime?>? sincronizadaEn,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return VentasCompanion(
      uuid: uuid ?? this.uuid,
      numero: numero ?? this.numero,
      usuarioUuid: usuarioUuid ?? this.usuarioUuid,
      dispositivoUuid: dispositivoUuid ?? this.dispositivoUuid,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      clienteDocumento: clienteDocumento ?? this.clienteDocumento,
      subtotal: subtotal ?? this.subtotal,
      descuentoTotal: descuentoTotal ?? this.descuentoTotal,
      impuestoTotal: impuestoTotal ?? this.impuestoTotal,
      total: total ?? this.total,
      costoTotal: costoTotal ?? this.costoTotal,
      metodoPago: metodoPago ?? this.metodoPago,
      montoRecibido: montoRecibido ?? this.montoRecibido,
      cambio: cambio ?? this.cambio,
      estado: estado ?? this.estado,
      anulaAVentaUuid: anulaAVentaUuid ?? this.anulaAVentaUuid,
      motivoAnulacion: motivoAnulacion ?? this.motivoAnulacion,
      notas: notas ?? this.notas,
      fecha: fecha ?? this.fecha,
      fechaLocal: fechaLocal ?? this.fechaLocal,
      creadaOffline: creadaOffline ?? this.creadaOffline,
      sincronizadaEn: sincronizadaEn ?? this.sincronizadaEn,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (numero.present) {
      map['numero'] = Variable<String>(numero.value);
    }
    if (usuarioUuid.present) {
      map['usuario_uuid'] = Variable<String>(usuarioUuid.value);
    }
    if (dispositivoUuid.present) {
      map['dispositivo_uuid'] = Variable<String>(dispositivoUuid.value);
    }
    if (clienteNombre.present) {
      map['cliente_nombre'] = Variable<String>(clienteNombre.value);
    }
    if (clienteDocumento.present) {
      map['cliente_documento'] = Variable<String>(clienteDocumento.value);
    }
    if (subtotal.present) {
      map['subtotal'] = Variable<int>(subtotal.value);
    }
    if (descuentoTotal.present) {
      map['descuento_total'] = Variable<int>(descuentoTotal.value);
    }
    if (impuestoTotal.present) {
      map['impuesto_total'] = Variable<int>(impuestoTotal.value);
    }
    if (total.present) {
      map['total'] = Variable<int>(total.value);
    }
    if (costoTotal.present) {
      map['costo_total'] = Variable<int>(costoTotal.value);
    }
    if (metodoPago.present) {
      map['metodo_pago'] = Variable<String>(metodoPago.value);
    }
    if (montoRecibido.present) {
      map['monto_recibido'] = Variable<int>(montoRecibido.value);
    }
    if (cambio.present) {
      map['cambio'] = Variable<int>(cambio.value);
    }
    if (estado.present) {
      map['estado'] = Variable<String>(estado.value);
    }
    if (anulaAVentaUuid.present) {
      map['anula_a_venta_uuid'] = Variable<String>(anulaAVentaUuid.value);
    }
    if (motivoAnulacion.present) {
      map['motivo_anulacion'] = Variable<String>(motivoAnulacion.value);
    }
    if (notas.present) {
      map['notas'] = Variable<String>(notas.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<DateTime>(fecha.value);
    }
    if (fechaLocal.present) {
      map['fecha_local'] = Variable<String>(fechaLocal.value);
    }
    if (creadaOffline.present) {
      map['creada_offline'] = Variable<bool>(creadaOffline.value);
    }
    if (sincronizadaEn.present) {
      map['sincronizada_en'] = Variable<DateTime>(sincronizadaEn.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VentasCompanion(')
          ..write('uuid: $uuid, ')
          ..write('numero: $numero, ')
          ..write('usuarioUuid: $usuarioUuid, ')
          ..write('dispositivoUuid: $dispositivoUuid, ')
          ..write('clienteNombre: $clienteNombre, ')
          ..write('clienteDocumento: $clienteDocumento, ')
          ..write('subtotal: $subtotal, ')
          ..write('descuentoTotal: $descuentoTotal, ')
          ..write('impuestoTotal: $impuestoTotal, ')
          ..write('total: $total, ')
          ..write('costoTotal: $costoTotal, ')
          ..write('metodoPago: $metodoPago, ')
          ..write('montoRecibido: $montoRecibido, ')
          ..write('cambio: $cambio, ')
          ..write('estado: $estado, ')
          ..write('anulaAVentaUuid: $anulaAVentaUuid, ')
          ..write('motivoAnulacion: $motivoAnulacion, ')
          ..write('notas: $notas, ')
          ..write('fecha: $fecha, ')
          ..write('fechaLocal: $fechaLocal, ')
          ..write('creadaOffline: $creadaOffline, ')
          ..write('sincronizadaEn: $sincronizadaEn, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $VentaDetallesTable extends VentaDetalles
    with TableInfo<$VentaDetallesTable, VentaDetalle> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $VentaDetallesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ventaUuidMeta = const VerificationMeta(
    'ventaUuid',
  );
  @override
  late final GeneratedColumn<String> ventaUuid = GeneratedColumn<String>(
    'venta_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productoUuidMeta = const VerificationMeta(
    'productoUuid',
  );
  @override
  late final GeneratedColumn<String> productoUuid = GeneratedColumn<String>(
    'producto_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lineaMeta = const VerificationMeta('linea');
  @override
  late final GeneratedColumn<int> linea = GeneratedColumn<int>(
    'linea',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _descripcionMeta = const VerificationMeta(
    'descripcion',
  );
  @override
  late final GeneratedColumn<String> descripcion = GeneratedColumn<String>(
    'descripcion',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _skuSnapshotMeta = const VerificationMeta(
    'skuSnapshot',
  );
  @override
  late final GeneratedColumn<String> skuSnapshot = GeneratedColumn<String>(
    'sku_snapshot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cantidadMeta = const VerificationMeta(
    'cantidad',
  );
  @override
  late final GeneratedColumn<int> cantidad = GeneratedColumn<int>(
    'cantidad',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _precioUnitarioMeta = const VerificationMeta(
    'precioUnitario',
  );
  @override
  late final GeneratedColumn<int> precioUnitario = GeneratedColumn<int>(
    'precio_unitario',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _costoUnitarioMeta = const VerificationMeta(
    'costoUnitario',
  );
  @override
  late final GeneratedColumn<int> costoUnitario = GeneratedColumn<int>(
    'costo_unitario',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _descuentoMeta = const VerificationMeta(
    'descuento',
  );
  @override
  late final GeneratedColumn<int> descuento = GeneratedColumn<int>(
    'descuento',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _tasaIvaMeta = const VerificationMeta(
    'tasaIva',
  );
  @override
  late final GeneratedColumn<int> tasaIva = GeneratedColumn<int>(
    'tasa_iva',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _baseGravableMeta = const VerificationMeta(
    'baseGravable',
  );
  @override
  late final GeneratedColumn<int> baseGravable = GeneratedColumn<int>(
    'base_gravable',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _impuestoMeta = const VerificationMeta(
    'impuesto',
  );
  @override
  late final GeneratedColumn<int> impuesto = GeneratedColumn<int>(
    'impuesto',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalMeta = const VerificationMeta('total');
  @override
  late final GeneratedColumn<int> total = GeneratedColumn<int>(
    'total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    ventaUuid,
    productoUuid,
    linea,
    descripcion,
    skuSnapshot,
    cantidad,
    precioUnitario,
    costoUnitario,
    descuento,
    tasaIva,
    baseGravable,
    impuesto,
    total,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'venta_detalles';
  @override
  VerificationContext validateIntegrity(
    Insertable<VentaDetalle> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('venta_uuid')) {
      context.handle(
        _ventaUuidMeta,
        ventaUuid.isAcceptableOrUnknown(data['venta_uuid']!, _ventaUuidMeta),
      );
    } else if (isInserting) {
      context.missing(_ventaUuidMeta);
    }
    if (data.containsKey('producto_uuid')) {
      context.handle(
        _productoUuidMeta,
        productoUuid.isAcceptableOrUnknown(
          data['producto_uuid']!,
          _productoUuidMeta,
        ),
      );
    }
    if (data.containsKey('linea')) {
      context.handle(
        _lineaMeta,
        linea.isAcceptableOrUnknown(data['linea']!, _lineaMeta),
      );
    }
    if (data.containsKey('descripcion')) {
      context.handle(
        _descripcionMeta,
        descripcion.isAcceptableOrUnknown(
          data['descripcion']!,
          _descripcionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descripcionMeta);
    }
    if (data.containsKey('sku_snapshot')) {
      context.handle(
        _skuSnapshotMeta,
        skuSnapshot.isAcceptableOrUnknown(
          data['sku_snapshot']!,
          _skuSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('cantidad')) {
      context.handle(
        _cantidadMeta,
        cantidad.isAcceptableOrUnknown(data['cantidad']!, _cantidadMeta),
      );
    } else if (isInserting) {
      context.missing(_cantidadMeta);
    }
    if (data.containsKey('precio_unitario')) {
      context.handle(
        _precioUnitarioMeta,
        precioUnitario.isAcceptableOrUnknown(
          data['precio_unitario']!,
          _precioUnitarioMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_precioUnitarioMeta);
    }
    if (data.containsKey('costo_unitario')) {
      context.handle(
        _costoUnitarioMeta,
        costoUnitario.isAcceptableOrUnknown(
          data['costo_unitario']!,
          _costoUnitarioMeta,
        ),
      );
    }
    if (data.containsKey('descuento')) {
      context.handle(
        _descuentoMeta,
        descuento.isAcceptableOrUnknown(data['descuento']!, _descuentoMeta),
      );
    }
    if (data.containsKey('tasa_iva')) {
      context.handle(
        _tasaIvaMeta,
        tasaIva.isAcceptableOrUnknown(data['tasa_iva']!, _tasaIvaMeta),
      );
    }
    if (data.containsKey('base_gravable')) {
      context.handle(
        _baseGravableMeta,
        baseGravable.isAcceptableOrUnknown(
          data['base_gravable']!,
          _baseGravableMeta,
        ),
      );
    }
    if (data.containsKey('impuesto')) {
      context.handle(
        _impuestoMeta,
        impuesto.isAcceptableOrUnknown(data['impuesto']!, _impuestoMeta),
      );
    }
    if (data.containsKey('total')) {
      context.handle(
        _totalMeta,
        total.isAcceptableOrUnknown(data['total']!, _totalMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  VentaDetalle map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VentaDetalle(
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      ventaUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}venta_uuid'],
      )!,
      productoUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}producto_uuid'],
      ),
      linea: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}linea'],
      )!,
      descripcion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}descripcion'],
      )!,
      skuSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sku_snapshot'],
      ),
      cantidad: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cantidad'],
      )!,
      precioUnitario: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}precio_unitario'],
      )!,
      costoUnitario: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}costo_unitario'],
      )!,
      descuento: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}descuento'],
      )!,
      tasaIva: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tasa_iva'],
      )!,
      baseGravable: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}base_gravable'],
      )!,
      impuesto: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}impuesto'],
      )!,
      total: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total'],
      )!,
    );
  }

  @override
  $VentaDetallesTable createAlias(String alias) {
    return $VentaDetallesTable(attachedDatabase, alias);
  }
}

class VentaDetalle extends DataClass implements Insertable<VentaDetalle> {
  final String uuid;
  final String ventaUuid;
  final String? productoUuid;
  final int linea;

  /// Instantánea del nombre al momento de vender: si mañana renombran el
  /// producto, el ticket histórico no debe cambiar.
  final String descripcion;
  final String? skuSnapshot;
  final int cantidad;
  final int precioUnitario;
  final int costoUnitario;
  final int descuento;
  final int tasaIva;
  final int baseGravable;
  final int impuesto;
  final int total;
  const VentaDetalle({
    required this.uuid,
    required this.ventaUuid,
    this.productoUuid,
    required this.linea,
    required this.descripcion,
    this.skuSnapshot,
    required this.cantidad,
    required this.precioUnitario,
    required this.costoUnitario,
    required this.descuento,
    required this.tasaIva,
    required this.baseGravable,
    required this.impuesto,
    required this.total,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid'] = Variable<String>(uuid);
    map['venta_uuid'] = Variable<String>(ventaUuid);
    if (!nullToAbsent || productoUuid != null) {
      map['producto_uuid'] = Variable<String>(productoUuid);
    }
    map['linea'] = Variable<int>(linea);
    map['descripcion'] = Variable<String>(descripcion);
    if (!nullToAbsent || skuSnapshot != null) {
      map['sku_snapshot'] = Variable<String>(skuSnapshot);
    }
    map['cantidad'] = Variable<int>(cantidad);
    map['precio_unitario'] = Variable<int>(precioUnitario);
    map['costo_unitario'] = Variable<int>(costoUnitario);
    map['descuento'] = Variable<int>(descuento);
    map['tasa_iva'] = Variable<int>(tasaIva);
    map['base_gravable'] = Variable<int>(baseGravable);
    map['impuesto'] = Variable<int>(impuesto);
    map['total'] = Variable<int>(total);
    return map;
  }

  VentaDetallesCompanion toCompanion(bool nullToAbsent) {
    return VentaDetallesCompanion(
      uuid: Value(uuid),
      ventaUuid: Value(ventaUuid),
      productoUuid: productoUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(productoUuid),
      linea: Value(linea),
      descripcion: Value(descripcion),
      skuSnapshot: skuSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(skuSnapshot),
      cantidad: Value(cantidad),
      precioUnitario: Value(precioUnitario),
      costoUnitario: Value(costoUnitario),
      descuento: Value(descuento),
      tasaIva: Value(tasaIva),
      baseGravable: Value(baseGravable),
      impuesto: Value(impuesto),
      total: Value(total),
    );
  }

  factory VentaDetalle.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VentaDetalle(
      uuid: serializer.fromJson<String>(json['uuid']),
      ventaUuid: serializer.fromJson<String>(json['ventaUuid']),
      productoUuid: serializer.fromJson<String?>(json['productoUuid']),
      linea: serializer.fromJson<int>(json['linea']),
      descripcion: serializer.fromJson<String>(json['descripcion']),
      skuSnapshot: serializer.fromJson<String?>(json['skuSnapshot']),
      cantidad: serializer.fromJson<int>(json['cantidad']),
      precioUnitario: serializer.fromJson<int>(json['precioUnitario']),
      costoUnitario: serializer.fromJson<int>(json['costoUnitario']),
      descuento: serializer.fromJson<int>(json['descuento']),
      tasaIva: serializer.fromJson<int>(json['tasaIva']),
      baseGravable: serializer.fromJson<int>(json['baseGravable']),
      impuesto: serializer.fromJson<int>(json['impuesto']),
      total: serializer.fromJson<int>(json['total']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String>(uuid),
      'ventaUuid': serializer.toJson<String>(ventaUuid),
      'productoUuid': serializer.toJson<String?>(productoUuid),
      'linea': serializer.toJson<int>(linea),
      'descripcion': serializer.toJson<String>(descripcion),
      'skuSnapshot': serializer.toJson<String?>(skuSnapshot),
      'cantidad': serializer.toJson<int>(cantidad),
      'precioUnitario': serializer.toJson<int>(precioUnitario),
      'costoUnitario': serializer.toJson<int>(costoUnitario),
      'descuento': serializer.toJson<int>(descuento),
      'tasaIva': serializer.toJson<int>(tasaIva),
      'baseGravable': serializer.toJson<int>(baseGravable),
      'impuesto': serializer.toJson<int>(impuesto),
      'total': serializer.toJson<int>(total),
    };
  }

  VentaDetalle copyWith({
    String? uuid,
    String? ventaUuid,
    Value<String?> productoUuid = const Value.absent(),
    int? linea,
    String? descripcion,
    Value<String?> skuSnapshot = const Value.absent(),
    int? cantidad,
    int? precioUnitario,
    int? costoUnitario,
    int? descuento,
    int? tasaIva,
    int? baseGravable,
    int? impuesto,
    int? total,
  }) => VentaDetalle(
    uuid: uuid ?? this.uuid,
    ventaUuid: ventaUuid ?? this.ventaUuid,
    productoUuid: productoUuid.present ? productoUuid.value : this.productoUuid,
    linea: linea ?? this.linea,
    descripcion: descripcion ?? this.descripcion,
    skuSnapshot: skuSnapshot.present ? skuSnapshot.value : this.skuSnapshot,
    cantidad: cantidad ?? this.cantidad,
    precioUnitario: precioUnitario ?? this.precioUnitario,
    costoUnitario: costoUnitario ?? this.costoUnitario,
    descuento: descuento ?? this.descuento,
    tasaIva: tasaIva ?? this.tasaIva,
    baseGravable: baseGravable ?? this.baseGravable,
    impuesto: impuesto ?? this.impuesto,
    total: total ?? this.total,
  );
  VentaDetalle copyWithCompanion(VentaDetallesCompanion data) {
    return VentaDetalle(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      ventaUuid: data.ventaUuid.present ? data.ventaUuid.value : this.ventaUuid,
      productoUuid: data.productoUuid.present
          ? data.productoUuid.value
          : this.productoUuid,
      linea: data.linea.present ? data.linea.value : this.linea,
      descripcion: data.descripcion.present
          ? data.descripcion.value
          : this.descripcion,
      skuSnapshot: data.skuSnapshot.present
          ? data.skuSnapshot.value
          : this.skuSnapshot,
      cantidad: data.cantidad.present ? data.cantidad.value : this.cantidad,
      precioUnitario: data.precioUnitario.present
          ? data.precioUnitario.value
          : this.precioUnitario,
      costoUnitario: data.costoUnitario.present
          ? data.costoUnitario.value
          : this.costoUnitario,
      descuento: data.descuento.present ? data.descuento.value : this.descuento,
      tasaIva: data.tasaIva.present ? data.tasaIva.value : this.tasaIva,
      baseGravable: data.baseGravable.present
          ? data.baseGravable.value
          : this.baseGravable,
      impuesto: data.impuesto.present ? data.impuesto.value : this.impuesto,
      total: data.total.present ? data.total.value : this.total,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VentaDetalle(')
          ..write('uuid: $uuid, ')
          ..write('ventaUuid: $ventaUuid, ')
          ..write('productoUuid: $productoUuid, ')
          ..write('linea: $linea, ')
          ..write('descripcion: $descripcion, ')
          ..write('skuSnapshot: $skuSnapshot, ')
          ..write('cantidad: $cantidad, ')
          ..write('precioUnitario: $precioUnitario, ')
          ..write('costoUnitario: $costoUnitario, ')
          ..write('descuento: $descuento, ')
          ..write('tasaIva: $tasaIva, ')
          ..write('baseGravable: $baseGravable, ')
          ..write('impuesto: $impuesto, ')
          ..write('total: $total')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    ventaUuid,
    productoUuid,
    linea,
    descripcion,
    skuSnapshot,
    cantidad,
    precioUnitario,
    costoUnitario,
    descuento,
    tasaIva,
    baseGravable,
    impuesto,
    total,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VentaDetalle &&
          other.uuid == this.uuid &&
          other.ventaUuid == this.ventaUuid &&
          other.productoUuid == this.productoUuid &&
          other.linea == this.linea &&
          other.descripcion == this.descripcion &&
          other.skuSnapshot == this.skuSnapshot &&
          other.cantidad == this.cantidad &&
          other.precioUnitario == this.precioUnitario &&
          other.costoUnitario == this.costoUnitario &&
          other.descuento == this.descuento &&
          other.tasaIva == this.tasaIva &&
          other.baseGravable == this.baseGravable &&
          other.impuesto == this.impuesto &&
          other.total == this.total);
}

class VentaDetallesCompanion extends UpdateCompanion<VentaDetalle> {
  final Value<String> uuid;
  final Value<String> ventaUuid;
  final Value<String?> productoUuid;
  final Value<int> linea;
  final Value<String> descripcion;
  final Value<String?> skuSnapshot;
  final Value<int> cantidad;
  final Value<int> precioUnitario;
  final Value<int> costoUnitario;
  final Value<int> descuento;
  final Value<int> tasaIva;
  final Value<int> baseGravable;
  final Value<int> impuesto;
  final Value<int> total;
  final Value<int> rowid;
  const VentaDetallesCompanion({
    this.uuid = const Value.absent(),
    this.ventaUuid = const Value.absent(),
    this.productoUuid = const Value.absent(),
    this.linea = const Value.absent(),
    this.descripcion = const Value.absent(),
    this.skuSnapshot = const Value.absent(),
    this.cantidad = const Value.absent(),
    this.precioUnitario = const Value.absent(),
    this.costoUnitario = const Value.absent(),
    this.descuento = const Value.absent(),
    this.tasaIva = const Value.absent(),
    this.baseGravable = const Value.absent(),
    this.impuesto = const Value.absent(),
    this.total = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  VentaDetallesCompanion.insert({
    required String uuid,
    required String ventaUuid,
    this.productoUuid = const Value.absent(),
    this.linea = const Value.absent(),
    required String descripcion,
    this.skuSnapshot = const Value.absent(),
    required int cantidad,
    required int precioUnitario,
    this.costoUnitario = const Value.absent(),
    this.descuento = const Value.absent(),
    this.tasaIva = const Value.absent(),
    this.baseGravable = const Value.absent(),
    this.impuesto = const Value.absent(),
    this.total = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       ventaUuid = Value(ventaUuid),
       descripcion = Value(descripcion),
       cantidad = Value(cantidad),
       precioUnitario = Value(precioUnitario);
  static Insertable<VentaDetalle> custom({
    Expression<String>? uuid,
    Expression<String>? ventaUuid,
    Expression<String>? productoUuid,
    Expression<int>? linea,
    Expression<String>? descripcion,
    Expression<String>? skuSnapshot,
    Expression<int>? cantidad,
    Expression<int>? precioUnitario,
    Expression<int>? costoUnitario,
    Expression<int>? descuento,
    Expression<int>? tasaIva,
    Expression<int>? baseGravable,
    Expression<int>? impuesto,
    Expression<int>? total,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (ventaUuid != null) 'venta_uuid': ventaUuid,
      if (productoUuid != null) 'producto_uuid': productoUuid,
      if (linea != null) 'linea': linea,
      if (descripcion != null) 'descripcion': descripcion,
      if (skuSnapshot != null) 'sku_snapshot': skuSnapshot,
      if (cantidad != null) 'cantidad': cantidad,
      if (precioUnitario != null) 'precio_unitario': precioUnitario,
      if (costoUnitario != null) 'costo_unitario': costoUnitario,
      if (descuento != null) 'descuento': descuento,
      if (tasaIva != null) 'tasa_iva': tasaIva,
      if (baseGravable != null) 'base_gravable': baseGravable,
      if (impuesto != null) 'impuesto': impuesto,
      if (total != null) 'total': total,
      if (rowid != null) 'rowid': rowid,
    });
  }

  VentaDetallesCompanion copyWith({
    Value<String>? uuid,
    Value<String>? ventaUuid,
    Value<String?>? productoUuid,
    Value<int>? linea,
    Value<String>? descripcion,
    Value<String?>? skuSnapshot,
    Value<int>? cantidad,
    Value<int>? precioUnitario,
    Value<int>? costoUnitario,
    Value<int>? descuento,
    Value<int>? tasaIva,
    Value<int>? baseGravable,
    Value<int>? impuesto,
    Value<int>? total,
    Value<int>? rowid,
  }) {
    return VentaDetallesCompanion(
      uuid: uuid ?? this.uuid,
      ventaUuid: ventaUuid ?? this.ventaUuid,
      productoUuid: productoUuid ?? this.productoUuid,
      linea: linea ?? this.linea,
      descripcion: descripcion ?? this.descripcion,
      skuSnapshot: skuSnapshot ?? this.skuSnapshot,
      cantidad: cantidad ?? this.cantidad,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      costoUnitario: costoUnitario ?? this.costoUnitario,
      descuento: descuento ?? this.descuento,
      tasaIva: tasaIva ?? this.tasaIva,
      baseGravable: baseGravable ?? this.baseGravable,
      impuesto: impuesto ?? this.impuesto,
      total: total ?? this.total,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (ventaUuid.present) {
      map['venta_uuid'] = Variable<String>(ventaUuid.value);
    }
    if (productoUuid.present) {
      map['producto_uuid'] = Variable<String>(productoUuid.value);
    }
    if (linea.present) {
      map['linea'] = Variable<int>(linea.value);
    }
    if (descripcion.present) {
      map['descripcion'] = Variable<String>(descripcion.value);
    }
    if (skuSnapshot.present) {
      map['sku_snapshot'] = Variable<String>(skuSnapshot.value);
    }
    if (cantidad.present) {
      map['cantidad'] = Variable<int>(cantidad.value);
    }
    if (precioUnitario.present) {
      map['precio_unitario'] = Variable<int>(precioUnitario.value);
    }
    if (costoUnitario.present) {
      map['costo_unitario'] = Variable<int>(costoUnitario.value);
    }
    if (descuento.present) {
      map['descuento'] = Variable<int>(descuento.value);
    }
    if (tasaIva.present) {
      map['tasa_iva'] = Variable<int>(tasaIva.value);
    }
    if (baseGravable.present) {
      map['base_gravable'] = Variable<int>(baseGravable.value);
    }
    if (impuesto.present) {
      map['impuesto'] = Variable<int>(impuesto.value);
    }
    if (total.present) {
      map['total'] = Variable<int>(total.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VentaDetallesCompanion(')
          ..write('uuid: $uuid, ')
          ..write('ventaUuid: $ventaUuid, ')
          ..write('productoUuid: $productoUuid, ')
          ..write('linea: $linea, ')
          ..write('descripcion: $descripcion, ')
          ..write('skuSnapshot: $skuSnapshot, ')
          ..write('cantidad: $cantidad, ')
          ..write('precioUnitario: $precioUnitario, ')
          ..write('costoUnitario: $costoUnitario, ')
          ..write('descuento: $descuento, ')
          ..write('tasaIva: $tasaIva, ')
          ..write('baseGravable: $baseGravable, ')
          ..write('impuesto: $impuesto, ')
          ..write('total: $total, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MovimientosTable extends Movimientos
    with TableInfo<$MovimientosTable, Movimiento> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MovimientosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _productoUuidMeta = const VerificationMeta(
    'productoUuid',
  );
  @override
  late final GeneratedColumn<String> productoUuid = GeneratedColumn<String>(
    'producto_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cantidadMeta = const VerificationMeta(
    'cantidad',
  );
  @override
  late final GeneratedColumn<int> cantidad = GeneratedColumn<int>(
    'cantidad',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _costoUnitarioMeta = const VerificationMeta(
    'costoUnitario',
  );
  @override
  late final GeneratedColumn<int> costoUnitario = GeneratedColumn<int>(
    'costo_unitario',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _precioUnitarioMeta = const VerificationMeta(
    'precioUnitario',
  );
  @override
  late final GeneratedColumn<int> precioUnitario = GeneratedColumn<int>(
    'precio_unitario',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stockAnteriorMeta = const VerificationMeta(
    'stockAnterior',
  );
  @override
  late final GeneratedColumn<int> stockAnterior = GeneratedColumn<int>(
    'stock_anterior',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _stockResultanteMeta = const VerificationMeta(
    'stockResultante',
  );
  @override
  late final GeneratedColumn<int> stockResultante = GeneratedColumn<int>(
    'stock_resultante',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ventaUuidMeta = const VerificationMeta(
    'ventaUuid',
  );
  @override
  late final GeneratedColumn<String> ventaUuid = GeneratedColumn<String>(
    'venta_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _proveedorUuidMeta = const VerificationMeta(
    'proveedorUuid',
  );
  @override
  late final GeneratedColumn<String> proveedorUuid = GeneratedColumn<String>(
    'proveedor_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _usuarioUuidMeta = const VerificationMeta(
    'usuarioUuid',
  );
  @override
  late final GeneratedColumn<String> usuarioUuid = GeneratedColumn<String>(
    'usuario_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _loteMeta = const VerificationMeta('lote');
  @override
  late final GeneratedColumn<String> lote = GeneratedColumn<String>(
    'lote',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _venceElMeta = const VerificationMeta(
    'venceEl',
  );
  @override
  late final GeneratedColumn<String> venceEl = GeneratedColumn<String>(
    'vence_el',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _documentoRefMeta = const VerificationMeta(
    'documentoRef',
  );
  @override
  late final GeneratedColumn<String> documentoRef = GeneratedColumn<String>(
    'documento_ref',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _motivoMeta = const VerificationMeta('motivo');
  @override
  late final GeneratedColumn<String> motivo = GeneratedColumn<String>(
    'motivo',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fechaMeta = const VerificationMeta('fecha');
  @override
  late final GeneratedColumn<DateTime> fecha = GeneratedColumn<DateTime>(
    'fecha',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fechaLocalMeta = const VerificationMeta(
    'fechaLocal',
  );
  @override
  late final GeneratedColumn<String> fechaLocal = GeneratedColumn<String>(
    'fecha_local',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _creadoOfflineMeta = const VerificationMeta(
    'creadoOffline',
  );
  @override
  late final GeneratedColumn<bool> creadoOffline = GeneratedColumn<bool>(
    'creado_offline',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("creado_offline" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _sincronizadoEnMeta = const VerificationMeta(
    'sincronizadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> sincronizadoEn =
      GeneratedColumn<DateTime>(
        'sincronizado_en',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    productoUuid,
    tipo,
    cantidad,
    costoUnitario,
    precioUnitario,
    stockAnterior,
    stockResultante,
    ventaUuid,
    proveedorUuid,
    usuarioUuid,
    lote,
    venceEl,
    documentoRef,
    motivo,
    fecha,
    fechaLocal,
    creadoOffline,
    sincronizadoEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'movimientos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Movimiento> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('producto_uuid')) {
      context.handle(
        _productoUuidMeta,
        productoUuid.isAcceptableOrUnknown(
          data['producto_uuid']!,
          _productoUuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productoUuidMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('cantidad')) {
      context.handle(
        _cantidadMeta,
        cantidad.isAcceptableOrUnknown(data['cantidad']!, _cantidadMeta),
      );
    } else if (isInserting) {
      context.missing(_cantidadMeta);
    }
    if (data.containsKey('costo_unitario')) {
      context.handle(
        _costoUnitarioMeta,
        costoUnitario.isAcceptableOrUnknown(
          data['costo_unitario']!,
          _costoUnitarioMeta,
        ),
      );
    }
    if (data.containsKey('precio_unitario')) {
      context.handle(
        _precioUnitarioMeta,
        precioUnitario.isAcceptableOrUnknown(
          data['precio_unitario']!,
          _precioUnitarioMeta,
        ),
      );
    }
    if (data.containsKey('stock_anterior')) {
      context.handle(
        _stockAnteriorMeta,
        stockAnterior.isAcceptableOrUnknown(
          data['stock_anterior']!,
          _stockAnteriorMeta,
        ),
      );
    }
    if (data.containsKey('stock_resultante')) {
      context.handle(
        _stockResultanteMeta,
        stockResultante.isAcceptableOrUnknown(
          data['stock_resultante']!,
          _stockResultanteMeta,
        ),
      );
    }
    if (data.containsKey('venta_uuid')) {
      context.handle(
        _ventaUuidMeta,
        ventaUuid.isAcceptableOrUnknown(data['venta_uuid']!, _ventaUuidMeta),
      );
    }
    if (data.containsKey('proveedor_uuid')) {
      context.handle(
        _proveedorUuidMeta,
        proveedorUuid.isAcceptableOrUnknown(
          data['proveedor_uuid']!,
          _proveedorUuidMeta,
        ),
      );
    }
    if (data.containsKey('usuario_uuid')) {
      context.handle(
        _usuarioUuidMeta,
        usuarioUuid.isAcceptableOrUnknown(
          data['usuario_uuid']!,
          _usuarioUuidMeta,
        ),
      );
    }
    if (data.containsKey('lote')) {
      context.handle(
        _loteMeta,
        lote.isAcceptableOrUnknown(data['lote']!, _loteMeta),
      );
    }
    if (data.containsKey('vence_el')) {
      context.handle(
        _venceElMeta,
        venceEl.isAcceptableOrUnknown(data['vence_el']!, _venceElMeta),
      );
    }
    if (data.containsKey('documento_ref')) {
      context.handle(
        _documentoRefMeta,
        documentoRef.isAcceptableOrUnknown(
          data['documento_ref']!,
          _documentoRefMeta,
        ),
      );
    }
    if (data.containsKey('motivo')) {
      context.handle(
        _motivoMeta,
        motivo.isAcceptableOrUnknown(data['motivo']!, _motivoMeta),
      );
    }
    if (data.containsKey('fecha')) {
      context.handle(
        _fechaMeta,
        fecha.isAcceptableOrUnknown(data['fecha']!, _fechaMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaMeta);
    }
    if (data.containsKey('fecha_local')) {
      context.handle(
        _fechaLocalMeta,
        fechaLocal.isAcceptableOrUnknown(data['fecha_local']!, _fechaLocalMeta),
      );
    } else if (isInserting) {
      context.missing(_fechaLocalMeta);
    }
    if (data.containsKey('creado_offline')) {
      context.handle(
        _creadoOfflineMeta,
        creadoOffline.isAcceptableOrUnknown(
          data['creado_offline']!,
          _creadoOfflineMeta,
        ),
      );
    }
    if (data.containsKey('sincronizado_en')) {
      context.handle(
        _sincronizadoEnMeta,
        sincronizadoEn.isAcceptableOrUnknown(
          data['sincronizado_en']!,
          _sincronizadoEnMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  Movimiento map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Movimiento(
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      productoUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}producto_uuid'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      cantidad: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cantidad'],
      )!,
      costoUnitario: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}costo_unitario'],
      ),
      precioUnitario: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}precio_unitario'],
      ),
      stockAnterior: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stock_anterior'],
      ),
      stockResultante: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}stock_resultante'],
      ),
      ventaUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}venta_uuid'],
      ),
      proveedorUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}proveedor_uuid'],
      ),
      usuarioUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}usuario_uuid'],
      ),
      lote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lote'],
      ),
      venceEl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vence_el'],
      ),
      documentoRef: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}documento_ref'],
      ),
      motivo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}motivo'],
      ),
      fecha: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}fecha'],
      )!,
      fechaLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fecha_local'],
      )!,
      creadoOffline: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}creado_offline'],
      )!,
      sincronizadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sincronizado_en'],
      ),
    );
  }

  @override
  $MovimientosTable createAlias(String alias) {
    return $MovimientosTable(attachedDatabase, alias);
  }
}

class Movimiento extends DataClass implements Insertable<Movimiento> {
  final String uuid;
  final String productoUuid;
  final String tipo;

  /// Con signo: positivo suma stock, negativo lo resta.
  final int cantidad;
  final int? costoUnitario;
  final int? precioUnitario;
  final int? stockAnterior;
  final int? stockResultante;
  final String? ventaUuid;
  final String? proveedorUuid;
  final String? usuarioUuid;
  final String? lote;
  final String? venceEl;
  final String? documentoRef;
  final String? motivo;
  final DateTime fecha;
  final String fechaLocal;
  final bool creadoOffline;
  final DateTime? sincronizadoEn;
  const Movimiento({
    required this.uuid,
    required this.productoUuid,
    required this.tipo,
    required this.cantidad,
    this.costoUnitario,
    this.precioUnitario,
    this.stockAnterior,
    this.stockResultante,
    this.ventaUuid,
    this.proveedorUuid,
    this.usuarioUuid,
    this.lote,
    this.venceEl,
    this.documentoRef,
    this.motivo,
    required this.fecha,
    required this.fechaLocal,
    required this.creadoOffline,
    this.sincronizadoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid'] = Variable<String>(uuid);
    map['producto_uuid'] = Variable<String>(productoUuid);
    map['tipo'] = Variable<String>(tipo);
    map['cantidad'] = Variable<int>(cantidad);
    if (!nullToAbsent || costoUnitario != null) {
      map['costo_unitario'] = Variable<int>(costoUnitario);
    }
    if (!nullToAbsent || precioUnitario != null) {
      map['precio_unitario'] = Variable<int>(precioUnitario);
    }
    if (!nullToAbsent || stockAnterior != null) {
      map['stock_anterior'] = Variable<int>(stockAnterior);
    }
    if (!nullToAbsent || stockResultante != null) {
      map['stock_resultante'] = Variable<int>(stockResultante);
    }
    if (!nullToAbsent || ventaUuid != null) {
      map['venta_uuid'] = Variable<String>(ventaUuid);
    }
    if (!nullToAbsent || proveedorUuid != null) {
      map['proveedor_uuid'] = Variable<String>(proveedorUuid);
    }
    if (!nullToAbsent || usuarioUuid != null) {
      map['usuario_uuid'] = Variable<String>(usuarioUuid);
    }
    if (!nullToAbsent || lote != null) {
      map['lote'] = Variable<String>(lote);
    }
    if (!nullToAbsent || venceEl != null) {
      map['vence_el'] = Variable<String>(venceEl);
    }
    if (!nullToAbsent || documentoRef != null) {
      map['documento_ref'] = Variable<String>(documentoRef);
    }
    if (!nullToAbsent || motivo != null) {
      map['motivo'] = Variable<String>(motivo);
    }
    map['fecha'] = Variable<DateTime>(fecha);
    map['fecha_local'] = Variable<String>(fechaLocal);
    map['creado_offline'] = Variable<bool>(creadoOffline);
    if (!nullToAbsent || sincronizadoEn != null) {
      map['sincronizado_en'] = Variable<DateTime>(sincronizadoEn);
    }
    return map;
  }

  MovimientosCompanion toCompanion(bool nullToAbsent) {
    return MovimientosCompanion(
      uuid: Value(uuid),
      productoUuid: Value(productoUuid),
      tipo: Value(tipo),
      cantidad: Value(cantidad),
      costoUnitario: costoUnitario == null && nullToAbsent
          ? const Value.absent()
          : Value(costoUnitario),
      precioUnitario: precioUnitario == null && nullToAbsent
          ? const Value.absent()
          : Value(precioUnitario),
      stockAnterior: stockAnterior == null && nullToAbsent
          ? const Value.absent()
          : Value(stockAnterior),
      stockResultante: stockResultante == null && nullToAbsent
          ? const Value.absent()
          : Value(stockResultante),
      ventaUuid: ventaUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(ventaUuid),
      proveedorUuid: proveedorUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(proveedorUuid),
      usuarioUuid: usuarioUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(usuarioUuid),
      lote: lote == null && nullToAbsent ? const Value.absent() : Value(lote),
      venceEl: venceEl == null && nullToAbsent
          ? const Value.absent()
          : Value(venceEl),
      documentoRef: documentoRef == null && nullToAbsent
          ? const Value.absent()
          : Value(documentoRef),
      motivo: motivo == null && nullToAbsent
          ? const Value.absent()
          : Value(motivo),
      fecha: Value(fecha),
      fechaLocal: Value(fechaLocal),
      creadoOffline: Value(creadoOffline),
      sincronizadoEn: sincronizadoEn == null && nullToAbsent
          ? const Value.absent()
          : Value(sincronizadoEn),
    );
  }

  factory Movimiento.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Movimiento(
      uuid: serializer.fromJson<String>(json['uuid']),
      productoUuid: serializer.fromJson<String>(json['productoUuid']),
      tipo: serializer.fromJson<String>(json['tipo']),
      cantidad: serializer.fromJson<int>(json['cantidad']),
      costoUnitario: serializer.fromJson<int?>(json['costoUnitario']),
      precioUnitario: serializer.fromJson<int?>(json['precioUnitario']),
      stockAnterior: serializer.fromJson<int?>(json['stockAnterior']),
      stockResultante: serializer.fromJson<int?>(json['stockResultante']),
      ventaUuid: serializer.fromJson<String?>(json['ventaUuid']),
      proveedorUuid: serializer.fromJson<String?>(json['proveedorUuid']),
      usuarioUuid: serializer.fromJson<String?>(json['usuarioUuid']),
      lote: serializer.fromJson<String?>(json['lote']),
      venceEl: serializer.fromJson<String?>(json['venceEl']),
      documentoRef: serializer.fromJson<String?>(json['documentoRef']),
      motivo: serializer.fromJson<String?>(json['motivo']),
      fecha: serializer.fromJson<DateTime>(json['fecha']),
      fechaLocal: serializer.fromJson<String>(json['fechaLocal']),
      creadoOffline: serializer.fromJson<bool>(json['creadoOffline']),
      sincronizadoEn: serializer.fromJson<DateTime?>(json['sincronizadoEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String>(uuid),
      'productoUuid': serializer.toJson<String>(productoUuid),
      'tipo': serializer.toJson<String>(tipo),
      'cantidad': serializer.toJson<int>(cantidad),
      'costoUnitario': serializer.toJson<int?>(costoUnitario),
      'precioUnitario': serializer.toJson<int?>(precioUnitario),
      'stockAnterior': serializer.toJson<int?>(stockAnterior),
      'stockResultante': serializer.toJson<int?>(stockResultante),
      'ventaUuid': serializer.toJson<String?>(ventaUuid),
      'proveedorUuid': serializer.toJson<String?>(proveedorUuid),
      'usuarioUuid': serializer.toJson<String?>(usuarioUuid),
      'lote': serializer.toJson<String?>(lote),
      'venceEl': serializer.toJson<String?>(venceEl),
      'documentoRef': serializer.toJson<String?>(documentoRef),
      'motivo': serializer.toJson<String?>(motivo),
      'fecha': serializer.toJson<DateTime>(fecha),
      'fechaLocal': serializer.toJson<String>(fechaLocal),
      'creadoOffline': serializer.toJson<bool>(creadoOffline),
      'sincronizadoEn': serializer.toJson<DateTime?>(sincronizadoEn),
    };
  }

  Movimiento copyWith({
    String? uuid,
    String? productoUuid,
    String? tipo,
    int? cantidad,
    Value<int?> costoUnitario = const Value.absent(),
    Value<int?> precioUnitario = const Value.absent(),
    Value<int?> stockAnterior = const Value.absent(),
    Value<int?> stockResultante = const Value.absent(),
    Value<String?> ventaUuid = const Value.absent(),
    Value<String?> proveedorUuid = const Value.absent(),
    Value<String?> usuarioUuid = const Value.absent(),
    Value<String?> lote = const Value.absent(),
    Value<String?> venceEl = const Value.absent(),
    Value<String?> documentoRef = const Value.absent(),
    Value<String?> motivo = const Value.absent(),
    DateTime? fecha,
    String? fechaLocal,
    bool? creadoOffline,
    Value<DateTime?> sincronizadoEn = const Value.absent(),
  }) => Movimiento(
    uuid: uuid ?? this.uuid,
    productoUuid: productoUuid ?? this.productoUuid,
    tipo: tipo ?? this.tipo,
    cantidad: cantidad ?? this.cantidad,
    costoUnitario: costoUnitario.present
        ? costoUnitario.value
        : this.costoUnitario,
    precioUnitario: precioUnitario.present
        ? precioUnitario.value
        : this.precioUnitario,
    stockAnterior: stockAnterior.present
        ? stockAnterior.value
        : this.stockAnterior,
    stockResultante: stockResultante.present
        ? stockResultante.value
        : this.stockResultante,
    ventaUuid: ventaUuid.present ? ventaUuid.value : this.ventaUuid,
    proveedorUuid: proveedorUuid.present
        ? proveedorUuid.value
        : this.proveedorUuid,
    usuarioUuid: usuarioUuid.present ? usuarioUuid.value : this.usuarioUuid,
    lote: lote.present ? lote.value : this.lote,
    venceEl: venceEl.present ? venceEl.value : this.venceEl,
    documentoRef: documentoRef.present ? documentoRef.value : this.documentoRef,
    motivo: motivo.present ? motivo.value : this.motivo,
    fecha: fecha ?? this.fecha,
    fechaLocal: fechaLocal ?? this.fechaLocal,
    creadoOffline: creadoOffline ?? this.creadoOffline,
    sincronizadoEn: sincronizadoEn.present
        ? sincronizadoEn.value
        : this.sincronizadoEn,
  );
  Movimiento copyWithCompanion(MovimientosCompanion data) {
    return Movimiento(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      productoUuid: data.productoUuid.present
          ? data.productoUuid.value
          : this.productoUuid,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      cantidad: data.cantidad.present ? data.cantidad.value : this.cantidad,
      costoUnitario: data.costoUnitario.present
          ? data.costoUnitario.value
          : this.costoUnitario,
      precioUnitario: data.precioUnitario.present
          ? data.precioUnitario.value
          : this.precioUnitario,
      stockAnterior: data.stockAnterior.present
          ? data.stockAnterior.value
          : this.stockAnterior,
      stockResultante: data.stockResultante.present
          ? data.stockResultante.value
          : this.stockResultante,
      ventaUuid: data.ventaUuid.present ? data.ventaUuid.value : this.ventaUuid,
      proveedorUuid: data.proveedorUuid.present
          ? data.proveedorUuid.value
          : this.proveedorUuid,
      usuarioUuid: data.usuarioUuid.present
          ? data.usuarioUuid.value
          : this.usuarioUuid,
      lote: data.lote.present ? data.lote.value : this.lote,
      venceEl: data.venceEl.present ? data.venceEl.value : this.venceEl,
      documentoRef: data.documentoRef.present
          ? data.documentoRef.value
          : this.documentoRef,
      motivo: data.motivo.present ? data.motivo.value : this.motivo,
      fecha: data.fecha.present ? data.fecha.value : this.fecha,
      fechaLocal: data.fechaLocal.present
          ? data.fechaLocal.value
          : this.fechaLocal,
      creadoOffline: data.creadoOffline.present
          ? data.creadoOffline.value
          : this.creadoOffline,
      sincronizadoEn: data.sincronizadoEn.present
          ? data.sincronizadoEn.value
          : this.sincronizadoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Movimiento(')
          ..write('uuid: $uuid, ')
          ..write('productoUuid: $productoUuid, ')
          ..write('tipo: $tipo, ')
          ..write('cantidad: $cantidad, ')
          ..write('costoUnitario: $costoUnitario, ')
          ..write('precioUnitario: $precioUnitario, ')
          ..write('stockAnterior: $stockAnterior, ')
          ..write('stockResultante: $stockResultante, ')
          ..write('ventaUuid: $ventaUuid, ')
          ..write('proveedorUuid: $proveedorUuid, ')
          ..write('usuarioUuid: $usuarioUuid, ')
          ..write('lote: $lote, ')
          ..write('venceEl: $venceEl, ')
          ..write('documentoRef: $documentoRef, ')
          ..write('motivo: $motivo, ')
          ..write('fecha: $fecha, ')
          ..write('fechaLocal: $fechaLocal, ')
          ..write('creadoOffline: $creadoOffline, ')
          ..write('sincronizadoEn: $sincronizadoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    productoUuid,
    tipo,
    cantidad,
    costoUnitario,
    precioUnitario,
    stockAnterior,
    stockResultante,
    ventaUuid,
    proveedorUuid,
    usuarioUuid,
    lote,
    venceEl,
    documentoRef,
    motivo,
    fecha,
    fechaLocal,
    creadoOffline,
    sincronizadoEn,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Movimiento &&
          other.uuid == this.uuid &&
          other.productoUuid == this.productoUuid &&
          other.tipo == this.tipo &&
          other.cantidad == this.cantidad &&
          other.costoUnitario == this.costoUnitario &&
          other.precioUnitario == this.precioUnitario &&
          other.stockAnterior == this.stockAnterior &&
          other.stockResultante == this.stockResultante &&
          other.ventaUuid == this.ventaUuid &&
          other.proveedorUuid == this.proveedorUuid &&
          other.usuarioUuid == this.usuarioUuid &&
          other.lote == this.lote &&
          other.venceEl == this.venceEl &&
          other.documentoRef == this.documentoRef &&
          other.motivo == this.motivo &&
          other.fecha == this.fecha &&
          other.fechaLocal == this.fechaLocal &&
          other.creadoOffline == this.creadoOffline &&
          other.sincronizadoEn == this.sincronizadoEn);
}

class MovimientosCompanion extends UpdateCompanion<Movimiento> {
  final Value<String> uuid;
  final Value<String> productoUuid;
  final Value<String> tipo;
  final Value<int> cantidad;
  final Value<int?> costoUnitario;
  final Value<int?> precioUnitario;
  final Value<int?> stockAnterior;
  final Value<int?> stockResultante;
  final Value<String?> ventaUuid;
  final Value<String?> proveedorUuid;
  final Value<String?> usuarioUuid;
  final Value<String?> lote;
  final Value<String?> venceEl;
  final Value<String?> documentoRef;
  final Value<String?> motivo;
  final Value<DateTime> fecha;
  final Value<String> fechaLocal;
  final Value<bool> creadoOffline;
  final Value<DateTime?> sincronizadoEn;
  final Value<int> rowid;
  const MovimientosCompanion({
    this.uuid = const Value.absent(),
    this.productoUuid = const Value.absent(),
    this.tipo = const Value.absent(),
    this.cantidad = const Value.absent(),
    this.costoUnitario = const Value.absent(),
    this.precioUnitario = const Value.absent(),
    this.stockAnterior = const Value.absent(),
    this.stockResultante = const Value.absent(),
    this.ventaUuid = const Value.absent(),
    this.proveedorUuid = const Value.absent(),
    this.usuarioUuid = const Value.absent(),
    this.lote = const Value.absent(),
    this.venceEl = const Value.absent(),
    this.documentoRef = const Value.absent(),
    this.motivo = const Value.absent(),
    this.fecha = const Value.absent(),
    this.fechaLocal = const Value.absent(),
    this.creadoOffline = const Value.absent(),
    this.sincronizadoEn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MovimientosCompanion.insert({
    required String uuid,
    required String productoUuid,
    required String tipo,
    required int cantidad,
    this.costoUnitario = const Value.absent(),
    this.precioUnitario = const Value.absent(),
    this.stockAnterior = const Value.absent(),
    this.stockResultante = const Value.absent(),
    this.ventaUuid = const Value.absent(),
    this.proveedorUuid = const Value.absent(),
    this.usuarioUuid = const Value.absent(),
    this.lote = const Value.absent(),
    this.venceEl = const Value.absent(),
    this.documentoRef = const Value.absent(),
    this.motivo = const Value.absent(),
    required DateTime fecha,
    required String fechaLocal,
    this.creadoOffline = const Value.absent(),
    this.sincronizadoEn = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       productoUuid = Value(productoUuid),
       tipo = Value(tipo),
       cantidad = Value(cantidad),
       fecha = Value(fecha),
       fechaLocal = Value(fechaLocal);
  static Insertable<Movimiento> custom({
    Expression<String>? uuid,
    Expression<String>? productoUuid,
    Expression<String>? tipo,
    Expression<int>? cantidad,
    Expression<int>? costoUnitario,
    Expression<int>? precioUnitario,
    Expression<int>? stockAnterior,
    Expression<int>? stockResultante,
    Expression<String>? ventaUuid,
    Expression<String>? proveedorUuid,
    Expression<String>? usuarioUuid,
    Expression<String>? lote,
    Expression<String>? venceEl,
    Expression<String>? documentoRef,
    Expression<String>? motivo,
    Expression<DateTime>? fecha,
    Expression<String>? fechaLocal,
    Expression<bool>? creadoOffline,
    Expression<DateTime>? sincronizadoEn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (productoUuid != null) 'producto_uuid': productoUuid,
      if (tipo != null) 'tipo': tipo,
      if (cantidad != null) 'cantidad': cantidad,
      if (costoUnitario != null) 'costo_unitario': costoUnitario,
      if (precioUnitario != null) 'precio_unitario': precioUnitario,
      if (stockAnterior != null) 'stock_anterior': stockAnterior,
      if (stockResultante != null) 'stock_resultante': stockResultante,
      if (ventaUuid != null) 'venta_uuid': ventaUuid,
      if (proveedorUuid != null) 'proveedor_uuid': proveedorUuid,
      if (usuarioUuid != null) 'usuario_uuid': usuarioUuid,
      if (lote != null) 'lote': lote,
      if (venceEl != null) 'vence_el': venceEl,
      if (documentoRef != null) 'documento_ref': documentoRef,
      if (motivo != null) 'motivo': motivo,
      if (fecha != null) 'fecha': fecha,
      if (fechaLocal != null) 'fecha_local': fechaLocal,
      if (creadoOffline != null) 'creado_offline': creadoOffline,
      if (sincronizadoEn != null) 'sincronizado_en': sincronizadoEn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MovimientosCompanion copyWith({
    Value<String>? uuid,
    Value<String>? productoUuid,
    Value<String>? tipo,
    Value<int>? cantidad,
    Value<int?>? costoUnitario,
    Value<int?>? precioUnitario,
    Value<int?>? stockAnterior,
    Value<int?>? stockResultante,
    Value<String?>? ventaUuid,
    Value<String?>? proveedorUuid,
    Value<String?>? usuarioUuid,
    Value<String?>? lote,
    Value<String?>? venceEl,
    Value<String?>? documentoRef,
    Value<String?>? motivo,
    Value<DateTime>? fecha,
    Value<String>? fechaLocal,
    Value<bool>? creadoOffline,
    Value<DateTime?>? sincronizadoEn,
    Value<int>? rowid,
  }) {
    return MovimientosCompanion(
      uuid: uuid ?? this.uuid,
      productoUuid: productoUuid ?? this.productoUuid,
      tipo: tipo ?? this.tipo,
      cantidad: cantidad ?? this.cantidad,
      costoUnitario: costoUnitario ?? this.costoUnitario,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      stockAnterior: stockAnterior ?? this.stockAnterior,
      stockResultante: stockResultante ?? this.stockResultante,
      ventaUuid: ventaUuid ?? this.ventaUuid,
      proveedorUuid: proveedorUuid ?? this.proveedorUuid,
      usuarioUuid: usuarioUuid ?? this.usuarioUuid,
      lote: lote ?? this.lote,
      venceEl: venceEl ?? this.venceEl,
      documentoRef: documentoRef ?? this.documentoRef,
      motivo: motivo ?? this.motivo,
      fecha: fecha ?? this.fecha,
      fechaLocal: fechaLocal ?? this.fechaLocal,
      creadoOffline: creadoOffline ?? this.creadoOffline,
      sincronizadoEn: sincronizadoEn ?? this.sincronizadoEn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (productoUuid.present) {
      map['producto_uuid'] = Variable<String>(productoUuid.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (cantidad.present) {
      map['cantidad'] = Variable<int>(cantidad.value);
    }
    if (costoUnitario.present) {
      map['costo_unitario'] = Variable<int>(costoUnitario.value);
    }
    if (precioUnitario.present) {
      map['precio_unitario'] = Variable<int>(precioUnitario.value);
    }
    if (stockAnterior.present) {
      map['stock_anterior'] = Variable<int>(stockAnterior.value);
    }
    if (stockResultante.present) {
      map['stock_resultante'] = Variable<int>(stockResultante.value);
    }
    if (ventaUuid.present) {
      map['venta_uuid'] = Variable<String>(ventaUuid.value);
    }
    if (proveedorUuid.present) {
      map['proveedor_uuid'] = Variable<String>(proveedorUuid.value);
    }
    if (usuarioUuid.present) {
      map['usuario_uuid'] = Variable<String>(usuarioUuid.value);
    }
    if (lote.present) {
      map['lote'] = Variable<String>(lote.value);
    }
    if (venceEl.present) {
      map['vence_el'] = Variable<String>(venceEl.value);
    }
    if (documentoRef.present) {
      map['documento_ref'] = Variable<String>(documentoRef.value);
    }
    if (motivo.present) {
      map['motivo'] = Variable<String>(motivo.value);
    }
    if (fecha.present) {
      map['fecha'] = Variable<DateTime>(fecha.value);
    }
    if (fechaLocal.present) {
      map['fecha_local'] = Variable<String>(fechaLocal.value);
    }
    if (creadoOffline.present) {
      map['creado_offline'] = Variable<bool>(creadoOffline.value);
    }
    if (sincronizadoEn.present) {
      map['sincronizado_en'] = Variable<DateTime>(sincronizadoEn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MovimientosCompanion(')
          ..write('uuid: $uuid, ')
          ..write('productoUuid: $productoUuid, ')
          ..write('tipo: $tipo, ')
          ..write('cantidad: $cantidad, ')
          ..write('costoUnitario: $costoUnitario, ')
          ..write('precioUnitario: $precioUnitario, ')
          ..write('stockAnterior: $stockAnterior, ')
          ..write('stockResultante: $stockResultante, ')
          ..write('ventaUuid: $ventaUuid, ')
          ..write('proveedorUuid: $proveedorUuid, ')
          ..write('usuarioUuid: $usuarioUuid, ')
          ..write('lote: $lote, ')
          ..write('venceEl: $venceEl, ')
          ..write('documentoRef: $documentoRef, ')
          ..write('motivo: $motivo, ')
          ..write('fecha: $fecha, ')
          ..write('fechaLocal: $fechaLocal, ')
          ..write('creadoOffline: $creadoOffline, ')
          ..write('sincronizadoEn: $sincronizadoEn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AlertasTable extends Alertas with TableInfo<$AlertasTable, Alerta> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AlertasTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _severidadMeta = const VerificationMeta(
    'severidad',
  );
  @override
  late final GeneratedColumn<String> severidad = GeneratedColumn<String>(
    'severidad',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('ADVERTENCIA'),
  );
  static const VerificationMeta _productoUuidMeta = const VerificationMeta(
    'productoUuid',
  );
  @override
  late final GeneratedColumn<String> productoUuid = GeneratedColumn<String>(
    'producto_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ventaUuidMeta = const VerificationMeta(
    'ventaUuid',
  );
  @override
  late final GeneratedColumn<String> ventaUuid = GeneratedColumn<String>(
    'venta_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _mensajeMeta = const VerificationMeta(
    'mensaje',
  );
  @override
  late final GeneratedColumn<String> mensaje = GeneratedColumn<String>(
    'mensaje',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _resueltaEnMeta = const VerificationMeta(
    'resueltaEn',
  );
  @override
  late final GeneratedColumn<DateTime> resueltaEn = GeneratedColumn<DateTime>(
    'resuelta_en',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    tipo,
    severidad,
    productoUuid,
    ventaUuid,
    mensaje,
    resueltaEn,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'alertas';
  @override
  VerificationContext validateIntegrity(
    Insertable<Alerta> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('severidad')) {
      context.handle(
        _severidadMeta,
        severidad.isAcceptableOrUnknown(data['severidad']!, _severidadMeta),
      );
    }
    if (data.containsKey('producto_uuid')) {
      context.handle(
        _productoUuidMeta,
        productoUuid.isAcceptableOrUnknown(
          data['producto_uuid']!,
          _productoUuidMeta,
        ),
      );
    }
    if (data.containsKey('venta_uuid')) {
      context.handle(
        _ventaUuidMeta,
        ventaUuid.isAcceptableOrUnknown(data['venta_uuid']!, _ventaUuidMeta),
      );
    }
    if (data.containsKey('mensaje')) {
      context.handle(
        _mensajeMeta,
        mensaje.isAcceptableOrUnknown(data['mensaje']!, _mensajeMeta),
      );
    } else if (isInserting) {
      context.missing(_mensajeMeta);
    }
    if (data.containsKey('resuelta_en')) {
      context.handle(
        _resueltaEnMeta,
        resueltaEn.isAcceptableOrUnknown(data['resuelta_en']!, _resueltaEnMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  Alerta map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Alerta(
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      severidad: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}severidad'],
      )!,
      productoUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}producto_uuid'],
      ),
      ventaUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}venta_uuid'],
      ),
      mensaje: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mensaje'],
      )!,
      resueltaEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}resuelta_en'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AlertasTable createAlias(String alias) {
    return $AlertasTable(attachedDatabase, alias);
  }
}

class Alerta extends DataClass implements Insertable<Alerta> {
  final String uuid;
  final String tipo;
  final String severidad;
  final String? productoUuid;
  final String? ventaUuid;
  final String mensaje;
  final DateTime? resueltaEn;
  final DateTime updatedAt;
  const Alerta({
    required this.uuid,
    required this.tipo,
    required this.severidad,
    this.productoUuid,
    this.ventaUuid,
    required this.mensaje,
    this.resueltaEn,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid'] = Variable<String>(uuid);
    map['tipo'] = Variable<String>(tipo);
    map['severidad'] = Variable<String>(severidad);
    if (!nullToAbsent || productoUuid != null) {
      map['producto_uuid'] = Variable<String>(productoUuid);
    }
    if (!nullToAbsent || ventaUuid != null) {
      map['venta_uuid'] = Variable<String>(ventaUuid);
    }
    map['mensaje'] = Variable<String>(mensaje);
    if (!nullToAbsent || resueltaEn != null) {
      map['resuelta_en'] = Variable<DateTime>(resueltaEn);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AlertasCompanion toCompanion(bool nullToAbsent) {
    return AlertasCompanion(
      uuid: Value(uuid),
      tipo: Value(tipo),
      severidad: Value(severidad),
      productoUuid: productoUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(productoUuid),
      ventaUuid: ventaUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(ventaUuid),
      mensaje: Value(mensaje),
      resueltaEn: resueltaEn == null && nullToAbsent
          ? const Value.absent()
          : Value(resueltaEn),
      updatedAt: Value(updatedAt),
    );
  }

  factory Alerta.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Alerta(
      uuid: serializer.fromJson<String>(json['uuid']),
      tipo: serializer.fromJson<String>(json['tipo']),
      severidad: serializer.fromJson<String>(json['severidad']),
      productoUuid: serializer.fromJson<String?>(json['productoUuid']),
      ventaUuid: serializer.fromJson<String?>(json['ventaUuid']),
      mensaje: serializer.fromJson<String>(json['mensaje']),
      resueltaEn: serializer.fromJson<DateTime?>(json['resueltaEn']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<String>(uuid),
      'tipo': serializer.toJson<String>(tipo),
      'severidad': serializer.toJson<String>(severidad),
      'productoUuid': serializer.toJson<String?>(productoUuid),
      'ventaUuid': serializer.toJson<String?>(ventaUuid),
      'mensaje': serializer.toJson<String>(mensaje),
      'resueltaEn': serializer.toJson<DateTime?>(resueltaEn),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Alerta copyWith({
    String? uuid,
    String? tipo,
    String? severidad,
    Value<String?> productoUuid = const Value.absent(),
    Value<String?> ventaUuid = const Value.absent(),
    String? mensaje,
    Value<DateTime?> resueltaEn = const Value.absent(),
    DateTime? updatedAt,
  }) => Alerta(
    uuid: uuid ?? this.uuid,
    tipo: tipo ?? this.tipo,
    severidad: severidad ?? this.severidad,
    productoUuid: productoUuid.present ? productoUuid.value : this.productoUuid,
    ventaUuid: ventaUuid.present ? ventaUuid.value : this.ventaUuid,
    mensaje: mensaje ?? this.mensaje,
    resueltaEn: resueltaEn.present ? resueltaEn.value : this.resueltaEn,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Alerta copyWithCompanion(AlertasCompanion data) {
    return Alerta(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      severidad: data.severidad.present ? data.severidad.value : this.severidad,
      productoUuid: data.productoUuid.present
          ? data.productoUuid.value
          : this.productoUuid,
      ventaUuid: data.ventaUuid.present ? data.ventaUuid.value : this.ventaUuid,
      mensaje: data.mensaje.present ? data.mensaje.value : this.mensaje,
      resueltaEn: data.resueltaEn.present
          ? data.resueltaEn.value
          : this.resueltaEn,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Alerta(')
          ..write('uuid: $uuid, ')
          ..write('tipo: $tipo, ')
          ..write('severidad: $severidad, ')
          ..write('productoUuid: $productoUuid, ')
          ..write('ventaUuid: $ventaUuid, ')
          ..write('mensaje: $mensaje, ')
          ..write('resueltaEn: $resueltaEn, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    tipo,
    severidad,
    productoUuid,
    ventaUuid,
    mensaje,
    resueltaEn,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Alerta &&
          other.uuid == this.uuid &&
          other.tipo == this.tipo &&
          other.severidad == this.severidad &&
          other.productoUuid == this.productoUuid &&
          other.ventaUuid == this.ventaUuid &&
          other.mensaje == this.mensaje &&
          other.resueltaEn == this.resueltaEn &&
          other.updatedAt == this.updatedAt);
}

class AlertasCompanion extends UpdateCompanion<Alerta> {
  final Value<String> uuid;
  final Value<String> tipo;
  final Value<String> severidad;
  final Value<String?> productoUuid;
  final Value<String?> ventaUuid;
  final Value<String> mensaje;
  final Value<DateTime?> resueltaEn;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AlertasCompanion({
    this.uuid = const Value.absent(),
    this.tipo = const Value.absent(),
    this.severidad = const Value.absent(),
    this.productoUuid = const Value.absent(),
    this.ventaUuid = const Value.absent(),
    this.mensaje = const Value.absent(),
    this.resueltaEn = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AlertasCompanion.insert({
    required String uuid,
    required String tipo,
    this.severidad = const Value.absent(),
    this.productoUuid = const Value.absent(),
    this.ventaUuid = const Value.absent(),
    required String mensaje,
    this.resueltaEn = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       tipo = Value(tipo),
       mensaje = Value(mensaje);
  static Insertable<Alerta> custom({
    Expression<String>? uuid,
    Expression<String>? tipo,
    Expression<String>? severidad,
    Expression<String>? productoUuid,
    Expression<String>? ventaUuid,
    Expression<String>? mensaje,
    Expression<DateTime>? resueltaEn,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (tipo != null) 'tipo': tipo,
      if (severidad != null) 'severidad': severidad,
      if (productoUuid != null) 'producto_uuid': productoUuid,
      if (ventaUuid != null) 'venta_uuid': ventaUuid,
      if (mensaje != null) 'mensaje': mensaje,
      if (resueltaEn != null) 'resuelta_en': resueltaEn,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AlertasCompanion copyWith({
    Value<String>? uuid,
    Value<String>? tipo,
    Value<String>? severidad,
    Value<String?>? productoUuid,
    Value<String?>? ventaUuid,
    Value<String>? mensaje,
    Value<DateTime?>? resueltaEn,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AlertasCompanion(
      uuid: uuid ?? this.uuid,
      tipo: tipo ?? this.tipo,
      severidad: severidad ?? this.severidad,
      productoUuid: productoUuid ?? this.productoUuid,
      ventaUuid: ventaUuid ?? this.ventaUuid,
      mensaje: mensaje ?? this.mensaje,
      resueltaEn: resueltaEn ?? this.resueltaEn,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (severidad.present) {
      map['severidad'] = Variable<String>(severidad.value);
    }
    if (productoUuid.present) {
      map['producto_uuid'] = Variable<String>(productoUuid.value);
    }
    if (ventaUuid.present) {
      map['venta_uuid'] = Variable<String>(ventaUuid.value);
    }
    if (mensaje.present) {
      map['mensaje'] = Variable<String>(mensaje.value);
    }
    if (resueltaEn.present) {
      map['resuelta_en'] = Variable<DateTime>(resueltaEn.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AlertasCompanion(')
          ..write('uuid: $uuid, ')
          ..write('tipo: $tipo, ')
          ..write('severidad: $severidad, ')
          ..write('productoUuid: $productoUuid, ')
          ..write('ventaUuid: $ventaUuid, ')
          ..write('mensaje: $mensaje, ')
          ..write('resueltaEn: $resueltaEn, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncOutboxTable extends SyncOutbox
    with TableInfo<$SyncOutboxTable, SyncOutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncOutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _clientOpIdMeta = const VerificationMeta(
    'clientOpId',
  );
  @override
  late final GeneratedColumn<String> clientOpId = GeneratedColumn<String>(
    'client_op_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entidadMeta = const VerificationMeta(
    'entidad',
  );
  @override
  late final GeneratedColumn<String> entidad = GeneratedColumn<String>(
    'entidad',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entidadUuidMeta = const VerificationMeta(
    'entidadUuid',
  );
  @override
  late final GeneratedColumn<String> entidadUuid = GeneratedColumn<String>(
    'entidad_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _intentosMeta = const VerificationMeta(
    'intentos',
  );
  @override
  late final GeneratedColumn<int> intentos = GeneratedColumn<int>(
    'intentos',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _ultimoErrorMeta = const VerificationMeta(
    'ultimoError',
  );
  @override
  late final GeneratedColumn<String> ultimoError = GeneratedColumn<String>(
    'ultimo_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _codigoErrorMeta = const VerificationMeta(
    'codigoError',
  );
  @override
  late final GeneratedColumn<String> codigoError = GeneratedColumn<String>(
    'codigo_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _estadoMeta = const VerificationMeta('estado');
  @override
  late final GeneratedColumn<String> estado = GeneratedColumn<String>(
    'estado',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('PENDIENTE'),
  );
  static const VerificationMeta _proximoIntentoMeta = const VerificationMeta(
    'proximoIntento',
  );
  @override
  late final GeneratedColumn<DateTime> proximoIntento =
      GeneratedColumn<DateTime>(
        'proximo_intento',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _creadoEnMeta = const VerificationMeta(
    'creadoEn',
  );
  @override
  late final GeneratedColumn<DateTime> creadoEn = GeneratedColumn<DateTime>(
    'creado_en',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    clientOpId,
    tipo,
    entidad,
    entidadUuid,
    payload,
    intentos,
    ultimoError,
    codigoError,
    estado,
    proximoIntento,
    creadoEn,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncOutboxData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_op_id')) {
      context.handle(
        _clientOpIdMeta,
        clientOpId.isAcceptableOrUnknown(
          data['client_op_id']!,
          _clientOpIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clientOpIdMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    } else if (isInserting) {
      context.missing(_tipoMeta);
    }
    if (data.containsKey('entidad')) {
      context.handle(
        _entidadMeta,
        entidad.isAcceptableOrUnknown(data['entidad']!, _entidadMeta),
      );
    } else if (isInserting) {
      context.missing(_entidadMeta);
    }
    if (data.containsKey('entidad_uuid')) {
      context.handle(
        _entidadUuidMeta,
        entidadUuid.isAcceptableOrUnknown(
          data['entidad_uuid']!,
          _entidadUuidMeta,
        ),
      );
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('intentos')) {
      context.handle(
        _intentosMeta,
        intentos.isAcceptableOrUnknown(data['intentos']!, _intentosMeta),
      );
    }
    if (data.containsKey('ultimo_error')) {
      context.handle(
        _ultimoErrorMeta,
        ultimoError.isAcceptableOrUnknown(
          data['ultimo_error']!,
          _ultimoErrorMeta,
        ),
      );
    }
    if (data.containsKey('codigo_error')) {
      context.handle(
        _codigoErrorMeta,
        codigoError.isAcceptableOrUnknown(
          data['codigo_error']!,
          _codigoErrorMeta,
        ),
      );
    }
    if (data.containsKey('estado')) {
      context.handle(
        _estadoMeta,
        estado.isAcceptableOrUnknown(data['estado']!, _estadoMeta),
      );
    }
    if (data.containsKey('proximo_intento')) {
      context.handle(
        _proximoIntentoMeta,
        proximoIntento.isAcceptableOrUnknown(
          data['proximo_intento']!,
          _proximoIntentoMeta,
        ),
      );
    }
    if (data.containsKey('creado_en')) {
      context.handle(
        _creadoEnMeta,
        creadoEn.isAcceptableOrUnknown(data['creado_en']!, _creadoEnMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncOutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncOutboxData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      clientOpId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_op_id'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
      entidad: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entidad'],
      )!,
      entidadUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entidad_uuid'],
      ),
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      intentos: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}intentos'],
      )!,
      ultimoError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ultimo_error'],
      ),
      codigoError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}codigo_error'],
      ),
      estado: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}estado'],
      )!,
      proximoIntento: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}proximo_intento'],
      )!,
      creadoEn: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}creado_en'],
      )!,
    );
  }

  @override
  $SyncOutboxTable createAlias(String alias) {
    return $SyncOutboxTable(attachedDatabase, alias);
  }
}

class SyncOutboxData extends DataClass implements Insertable<SyncOutboxData> {
  final int id;

  /// Clave de idempotencia. El servidor la usa para no aplicar dos veces el
  /// mismo efecto cuando se pierde la respuesta y el cliente reintenta.
  final String clientOpId;
  final String tipo;
  final String entidad;
  final String? entidadUuid;
  final String payload;
  final int intentos;
  final String? ultimoError;
  final String? codigoError;

  /// PENDIENTE · ENVIANDO · RECHAZADA
  final String estado;
  final DateTime proximoIntento;
  final DateTime creadoEn;
  const SyncOutboxData({
    required this.id,
    required this.clientOpId,
    required this.tipo,
    required this.entidad,
    this.entidadUuid,
    required this.payload,
    required this.intentos,
    this.ultimoError,
    this.codigoError,
    required this.estado,
    required this.proximoIntento,
    required this.creadoEn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['client_op_id'] = Variable<String>(clientOpId);
    map['tipo'] = Variable<String>(tipo);
    map['entidad'] = Variable<String>(entidad);
    if (!nullToAbsent || entidadUuid != null) {
      map['entidad_uuid'] = Variable<String>(entidadUuid);
    }
    map['payload'] = Variable<String>(payload);
    map['intentos'] = Variable<int>(intentos);
    if (!nullToAbsent || ultimoError != null) {
      map['ultimo_error'] = Variable<String>(ultimoError);
    }
    if (!nullToAbsent || codigoError != null) {
      map['codigo_error'] = Variable<String>(codigoError);
    }
    map['estado'] = Variable<String>(estado);
    map['proximo_intento'] = Variable<DateTime>(proximoIntento);
    map['creado_en'] = Variable<DateTime>(creadoEn);
    return map;
  }

  SyncOutboxCompanion toCompanion(bool nullToAbsent) {
    return SyncOutboxCompanion(
      id: Value(id),
      clientOpId: Value(clientOpId),
      tipo: Value(tipo),
      entidad: Value(entidad),
      entidadUuid: entidadUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(entidadUuid),
      payload: Value(payload),
      intentos: Value(intentos),
      ultimoError: ultimoError == null && nullToAbsent
          ? const Value.absent()
          : Value(ultimoError),
      codigoError: codigoError == null && nullToAbsent
          ? const Value.absent()
          : Value(codigoError),
      estado: Value(estado),
      proximoIntento: Value(proximoIntento),
      creadoEn: Value(creadoEn),
    );
  }

  factory SyncOutboxData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncOutboxData(
      id: serializer.fromJson<int>(json['id']),
      clientOpId: serializer.fromJson<String>(json['clientOpId']),
      tipo: serializer.fromJson<String>(json['tipo']),
      entidad: serializer.fromJson<String>(json['entidad']),
      entidadUuid: serializer.fromJson<String?>(json['entidadUuid']),
      payload: serializer.fromJson<String>(json['payload']),
      intentos: serializer.fromJson<int>(json['intentos']),
      ultimoError: serializer.fromJson<String?>(json['ultimoError']),
      codigoError: serializer.fromJson<String?>(json['codigoError']),
      estado: serializer.fromJson<String>(json['estado']),
      proximoIntento: serializer.fromJson<DateTime>(json['proximoIntento']),
      creadoEn: serializer.fromJson<DateTime>(json['creadoEn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientOpId': serializer.toJson<String>(clientOpId),
      'tipo': serializer.toJson<String>(tipo),
      'entidad': serializer.toJson<String>(entidad),
      'entidadUuid': serializer.toJson<String?>(entidadUuid),
      'payload': serializer.toJson<String>(payload),
      'intentos': serializer.toJson<int>(intentos),
      'ultimoError': serializer.toJson<String?>(ultimoError),
      'codigoError': serializer.toJson<String?>(codigoError),
      'estado': serializer.toJson<String>(estado),
      'proximoIntento': serializer.toJson<DateTime>(proximoIntento),
      'creadoEn': serializer.toJson<DateTime>(creadoEn),
    };
  }

  SyncOutboxData copyWith({
    int? id,
    String? clientOpId,
    String? tipo,
    String? entidad,
    Value<String?> entidadUuid = const Value.absent(),
    String? payload,
    int? intentos,
    Value<String?> ultimoError = const Value.absent(),
    Value<String?> codigoError = const Value.absent(),
    String? estado,
    DateTime? proximoIntento,
    DateTime? creadoEn,
  }) => SyncOutboxData(
    id: id ?? this.id,
    clientOpId: clientOpId ?? this.clientOpId,
    tipo: tipo ?? this.tipo,
    entidad: entidad ?? this.entidad,
    entidadUuid: entidadUuid.present ? entidadUuid.value : this.entidadUuid,
    payload: payload ?? this.payload,
    intentos: intentos ?? this.intentos,
    ultimoError: ultimoError.present ? ultimoError.value : this.ultimoError,
    codigoError: codigoError.present ? codigoError.value : this.codigoError,
    estado: estado ?? this.estado,
    proximoIntento: proximoIntento ?? this.proximoIntento,
    creadoEn: creadoEn ?? this.creadoEn,
  );
  SyncOutboxData copyWithCompanion(SyncOutboxCompanion data) {
    return SyncOutboxData(
      id: data.id.present ? data.id.value : this.id,
      clientOpId: data.clientOpId.present
          ? data.clientOpId.value
          : this.clientOpId,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
      entidad: data.entidad.present ? data.entidad.value : this.entidad,
      entidadUuid: data.entidadUuid.present
          ? data.entidadUuid.value
          : this.entidadUuid,
      payload: data.payload.present ? data.payload.value : this.payload,
      intentos: data.intentos.present ? data.intentos.value : this.intentos,
      ultimoError: data.ultimoError.present
          ? data.ultimoError.value
          : this.ultimoError,
      codigoError: data.codigoError.present
          ? data.codigoError.value
          : this.codigoError,
      estado: data.estado.present ? data.estado.value : this.estado,
      proximoIntento: data.proximoIntento.present
          ? data.proximoIntento.value
          : this.proximoIntento,
      creadoEn: data.creadoEn.present ? data.creadoEn.value : this.creadoEn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxData(')
          ..write('id: $id, ')
          ..write('clientOpId: $clientOpId, ')
          ..write('tipo: $tipo, ')
          ..write('entidad: $entidad, ')
          ..write('entidadUuid: $entidadUuid, ')
          ..write('payload: $payload, ')
          ..write('intentos: $intentos, ')
          ..write('ultimoError: $ultimoError, ')
          ..write('codigoError: $codigoError, ')
          ..write('estado: $estado, ')
          ..write('proximoIntento: $proximoIntento, ')
          ..write('creadoEn: $creadoEn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    clientOpId,
    tipo,
    entidad,
    entidadUuid,
    payload,
    intentos,
    ultimoError,
    codigoError,
    estado,
    proximoIntento,
    creadoEn,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncOutboxData &&
          other.id == this.id &&
          other.clientOpId == this.clientOpId &&
          other.tipo == this.tipo &&
          other.entidad == this.entidad &&
          other.entidadUuid == this.entidadUuid &&
          other.payload == this.payload &&
          other.intentos == this.intentos &&
          other.ultimoError == this.ultimoError &&
          other.codigoError == this.codigoError &&
          other.estado == this.estado &&
          other.proximoIntento == this.proximoIntento &&
          other.creadoEn == this.creadoEn);
}

class SyncOutboxCompanion extends UpdateCompanion<SyncOutboxData> {
  final Value<int> id;
  final Value<String> clientOpId;
  final Value<String> tipo;
  final Value<String> entidad;
  final Value<String?> entidadUuid;
  final Value<String> payload;
  final Value<int> intentos;
  final Value<String?> ultimoError;
  final Value<String?> codigoError;
  final Value<String> estado;
  final Value<DateTime> proximoIntento;
  final Value<DateTime> creadoEn;
  const SyncOutboxCompanion({
    this.id = const Value.absent(),
    this.clientOpId = const Value.absent(),
    this.tipo = const Value.absent(),
    this.entidad = const Value.absent(),
    this.entidadUuid = const Value.absent(),
    this.payload = const Value.absent(),
    this.intentos = const Value.absent(),
    this.ultimoError = const Value.absent(),
    this.codigoError = const Value.absent(),
    this.estado = const Value.absent(),
    this.proximoIntento = const Value.absent(),
    this.creadoEn = const Value.absent(),
  });
  SyncOutboxCompanion.insert({
    this.id = const Value.absent(),
    required String clientOpId,
    required String tipo,
    required String entidad,
    this.entidadUuid = const Value.absent(),
    required String payload,
    this.intentos = const Value.absent(),
    this.ultimoError = const Value.absent(),
    this.codigoError = const Value.absent(),
    this.estado = const Value.absent(),
    this.proximoIntento = const Value.absent(),
    this.creadoEn = const Value.absent(),
  }) : clientOpId = Value(clientOpId),
       tipo = Value(tipo),
       entidad = Value(entidad),
       payload = Value(payload);
  static Insertable<SyncOutboxData> custom({
    Expression<int>? id,
    Expression<String>? clientOpId,
    Expression<String>? tipo,
    Expression<String>? entidad,
    Expression<String>? entidadUuid,
    Expression<String>? payload,
    Expression<int>? intentos,
    Expression<String>? ultimoError,
    Expression<String>? codigoError,
    Expression<String>? estado,
    Expression<DateTime>? proximoIntento,
    Expression<DateTime>? creadoEn,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientOpId != null) 'client_op_id': clientOpId,
      if (tipo != null) 'tipo': tipo,
      if (entidad != null) 'entidad': entidad,
      if (entidadUuid != null) 'entidad_uuid': entidadUuid,
      if (payload != null) 'payload': payload,
      if (intentos != null) 'intentos': intentos,
      if (ultimoError != null) 'ultimo_error': ultimoError,
      if (codigoError != null) 'codigo_error': codigoError,
      if (estado != null) 'estado': estado,
      if (proximoIntento != null) 'proximo_intento': proximoIntento,
      if (creadoEn != null) 'creado_en': creadoEn,
    });
  }

  SyncOutboxCompanion copyWith({
    Value<int>? id,
    Value<String>? clientOpId,
    Value<String>? tipo,
    Value<String>? entidad,
    Value<String?>? entidadUuid,
    Value<String>? payload,
    Value<int>? intentos,
    Value<String?>? ultimoError,
    Value<String?>? codigoError,
    Value<String>? estado,
    Value<DateTime>? proximoIntento,
    Value<DateTime>? creadoEn,
  }) {
    return SyncOutboxCompanion(
      id: id ?? this.id,
      clientOpId: clientOpId ?? this.clientOpId,
      tipo: tipo ?? this.tipo,
      entidad: entidad ?? this.entidad,
      entidadUuid: entidadUuid ?? this.entidadUuid,
      payload: payload ?? this.payload,
      intentos: intentos ?? this.intentos,
      ultimoError: ultimoError ?? this.ultimoError,
      codigoError: codigoError ?? this.codigoError,
      estado: estado ?? this.estado,
      proximoIntento: proximoIntento ?? this.proximoIntento,
      creadoEn: creadoEn ?? this.creadoEn,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (clientOpId.present) {
      map['client_op_id'] = Variable<String>(clientOpId.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (entidad.present) {
      map['entidad'] = Variable<String>(entidad.value);
    }
    if (entidadUuid.present) {
      map['entidad_uuid'] = Variable<String>(entidadUuid.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (intentos.present) {
      map['intentos'] = Variable<int>(intentos.value);
    }
    if (ultimoError.present) {
      map['ultimo_error'] = Variable<String>(ultimoError.value);
    }
    if (codigoError.present) {
      map['codigo_error'] = Variable<String>(codigoError.value);
    }
    if (estado.present) {
      map['estado'] = Variable<String>(estado.value);
    }
    if (proximoIntento.present) {
      map['proximo_intento'] = Variable<DateTime>(proximoIntento.value);
    }
    if (creadoEn.present) {
      map['creado_en'] = Variable<DateTime>(creadoEn.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxCompanion(')
          ..write('id: $id, ')
          ..write('clientOpId: $clientOpId, ')
          ..write('tipo: $tipo, ')
          ..write('entidad: $entidad, ')
          ..write('entidadUuid: $entidadUuid, ')
          ..write('payload: $payload, ')
          ..write('intentos: $intentos, ')
          ..write('ultimoError: $ultimoError, ')
          ..write('codigoError: $codigoError, ')
          ..write('estado: $estado, ')
          ..write('proximoIntento: $proximoIntento, ')
          ..write('creadoEn: $creadoEn')
          ..write(')'))
        .toString();
  }
}

class $SyncCursoresTable extends SyncCursores
    with TableInfo<$SyncCursoresTable, SyncCursor> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncCursoresTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entidadMeta = const VerificationMeta(
    'entidad',
  );
  @override
  late final GeneratedColumn<String> entidad = GeneratedColumn<String>(
    'entidad',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cursorTMeta = const VerificationMeta(
    'cursorT',
  );
  @override
  late final GeneratedColumn<DateTime> cursorT = GeneratedColumn<DateTime>(
    'cursor_t',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cursorIMeta = const VerificationMeta(
    'cursorI',
  );
  @override
  late final GeneratedColumn<int> cursorI = GeneratedColumn<int>(
    'cursor_i',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _ultimoSyncMeta = const VerificationMeta(
    'ultimoSync',
  );
  @override
  late final GeneratedColumn<DateTime> ultimoSync = GeneratedColumn<DateTime>(
    'ultimo_sync',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [entidad, cursorT, cursorI, ultimoSync];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_cursores';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncCursor> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entidad')) {
      context.handle(
        _entidadMeta,
        entidad.isAcceptableOrUnknown(data['entidad']!, _entidadMeta),
      );
    } else if (isInserting) {
      context.missing(_entidadMeta);
    }
    if (data.containsKey('cursor_t')) {
      context.handle(
        _cursorTMeta,
        cursorT.isAcceptableOrUnknown(data['cursor_t']!, _cursorTMeta),
      );
    } else if (isInserting) {
      context.missing(_cursorTMeta);
    }
    if (data.containsKey('cursor_i')) {
      context.handle(
        _cursorIMeta,
        cursorI.isAcceptableOrUnknown(data['cursor_i']!, _cursorIMeta),
      );
    }
    if (data.containsKey('ultimo_sync')) {
      context.handle(
        _ultimoSyncMeta,
        ultimoSync.isAcceptableOrUnknown(data['ultimo_sync']!, _ultimoSyncMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entidad};
  @override
  SyncCursor map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncCursor(
      entidad: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entidad'],
      )!,
      cursorT: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cursor_t'],
      )!,
      cursorI: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cursor_i'],
      )!,
      ultimoSync: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ultimo_sync'],
      ),
    );
  }

  @override
  $SyncCursoresTable createAlias(String alias) {
    return $SyncCursoresTable(attachedDatabase, alias);
  }
}

class SyncCursor extends DataClass implements Insertable<SyncCursor> {
  final String entidad;
  final DateTime cursorT;
  final int cursorI;
  final DateTime? ultimoSync;
  const SyncCursor({
    required this.entidad,
    required this.cursorT,
    required this.cursorI,
    this.ultimoSync,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entidad'] = Variable<String>(entidad);
    map['cursor_t'] = Variable<DateTime>(cursorT);
    map['cursor_i'] = Variable<int>(cursorI);
    if (!nullToAbsent || ultimoSync != null) {
      map['ultimo_sync'] = Variable<DateTime>(ultimoSync);
    }
    return map;
  }

  SyncCursoresCompanion toCompanion(bool nullToAbsent) {
    return SyncCursoresCompanion(
      entidad: Value(entidad),
      cursorT: Value(cursorT),
      cursorI: Value(cursorI),
      ultimoSync: ultimoSync == null && nullToAbsent
          ? const Value.absent()
          : Value(ultimoSync),
    );
  }

  factory SyncCursor.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncCursor(
      entidad: serializer.fromJson<String>(json['entidad']),
      cursorT: serializer.fromJson<DateTime>(json['cursorT']),
      cursorI: serializer.fromJson<int>(json['cursorI']),
      ultimoSync: serializer.fromJson<DateTime?>(json['ultimoSync']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entidad': serializer.toJson<String>(entidad),
      'cursorT': serializer.toJson<DateTime>(cursorT),
      'cursorI': serializer.toJson<int>(cursorI),
      'ultimoSync': serializer.toJson<DateTime?>(ultimoSync),
    };
  }

  SyncCursor copyWith({
    String? entidad,
    DateTime? cursorT,
    int? cursorI,
    Value<DateTime?> ultimoSync = const Value.absent(),
  }) => SyncCursor(
    entidad: entidad ?? this.entidad,
    cursorT: cursorT ?? this.cursorT,
    cursorI: cursorI ?? this.cursorI,
    ultimoSync: ultimoSync.present ? ultimoSync.value : this.ultimoSync,
  );
  SyncCursor copyWithCompanion(SyncCursoresCompanion data) {
    return SyncCursor(
      entidad: data.entidad.present ? data.entidad.value : this.entidad,
      cursorT: data.cursorT.present ? data.cursorT.value : this.cursorT,
      cursorI: data.cursorI.present ? data.cursorI.value : this.cursorI,
      ultimoSync: data.ultimoSync.present
          ? data.ultimoSync.value
          : this.ultimoSync,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursor(')
          ..write('entidad: $entidad, ')
          ..write('cursorT: $cursorT, ')
          ..write('cursorI: $cursorI, ')
          ..write('ultimoSync: $ultimoSync')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(entidad, cursorT, cursorI, ultimoSync);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncCursor &&
          other.entidad == this.entidad &&
          other.cursorT == this.cursorT &&
          other.cursorI == this.cursorI &&
          other.ultimoSync == this.ultimoSync);
}

class SyncCursoresCompanion extends UpdateCompanion<SyncCursor> {
  final Value<String> entidad;
  final Value<DateTime> cursorT;
  final Value<int> cursorI;
  final Value<DateTime?> ultimoSync;
  final Value<int> rowid;
  const SyncCursoresCompanion({
    this.entidad = const Value.absent(),
    this.cursorT = const Value.absent(),
    this.cursorI = const Value.absent(),
    this.ultimoSync = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncCursoresCompanion.insert({
    required String entidad,
    required DateTime cursorT,
    this.cursorI = const Value.absent(),
    this.ultimoSync = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : entidad = Value(entidad),
       cursorT = Value(cursorT);
  static Insertable<SyncCursor> custom({
    Expression<String>? entidad,
    Expression<DateTime>? cursorT,
    Expression<int>? cursorI,
    Expression<DateTime>? ultimoSync,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entidad != null) 'entidad': entidad,
      if (cursorT != null) 'cursor_t': cursorT,
      if (cursorI != null) 'cursor_i': cursorI,
      if (ultimoSync != null) 'ultimo_sync': ultimoSync,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncCursoresCompanion copyWith({
    Value<String>? entidad,
    Value<DateTime>? cursorT,
    Value<int>? cursorI,
    Value<DateTime?>? ultimoSync,
    Value<int>? rowid,
  }) {
    return SyncCursoresCompanion(
      entidad: entidad ?? this.entidad,
      cursorT: cursorT ?? this.cursorT,
      cursorI: cursorI ?? this.cursorI,
      ultimoSync: ultimoSync ?? this.ultimoSync,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entidad.present) {
      map['entidad'] = Variable<String>(entidad.value);
    }
    if (cursorT.present) {
      map['cursor_t'] = Variable<DateTime>(cursorT.value);
    }
    if (cursorI.present) {
      map['cursor_i'] = Variable<int>(cursorI.value);
    }
    if (ultimoSync.present) {
      map['ultimo_sync'] = Variable<DateTime>(ultimoSync.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursoresCompanion(')
          ..write('entidad: $entidad, ')
          ..write('cursorT: $cursorT, ')
          ..write('cursorI: $cursorI, ')
          ..write('ultimoSync: $ultimoSync, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ConfiguracionTable extends Configuracion
    with TableInfo<$ConfiguracionTable, ConfiguracionData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConfiguracionTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _claveMeta = const VerificationMeta('clave');
  @override
  late final GeneratedColumn<String> clave = GeneratedColumn<String>(
    'clave',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valorMeta = const VerificationMeta('valor');
  @override
  late final GeneratedColumn<String> valor = GeneratedColumn<String>(
    'valor',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tipoMeta = const VerificationMeta('tipo');
  @override
  late final GeneratedColumn<String> tipo = GeneratedColumn<String>(
    'tipo',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('STRING'),
  );
  @override
  List<GeneratedColumn> get $columns => [clave, valor, tipo];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'configuracion';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConfiguracionData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('clave')) {
      context.handle(
        _claveMeta,
        clave.isAcceptableOrUnknown(data['clave']!, _claveMeta),
      );
    } else if (isInserting) {
      context.missing(_claveMeta);
    }
    if (data.containsKey('valor')) {
      context.handle(
        _valorMeta,
        valor.isAcceptableOrUnknown(data['valor']!, _valorMeta),
      );
    } else if (isInserting) {
      context.missing(_valorMeta);
    }
    if (data.containsKey('tipo')) {
      context.handle(
        _tipoMeta,
        tipo.isAcceptableOrUnknown(data['tipo']!, _tipoMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {clave};
  @override
  ConfiguracionData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConfiguracionData(
      clave: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}clave'],
      )!,
      valor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}valor'],
      )!,
      tipo: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tipo'],
      )!,
    );
  }

  @override
  $ConfiguracionTable createAlias(String alias) {
    return $ConfiguracionTable(attachedDatabase, alias);
  }
}

class ConfiguracionData extends DataClass
    implements Insertable<ConfiguracionData> {
  final String clave;
  final String valor;
  final String tipo;
  const ConfiguracionData({
    required this.clave,
    required this.valor,
    required this.tipo,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['clave'] = Variable<String>(clave);
    map['valor'] = Variable<String>(valor);
    map['tipo'] = Variable<String>(tipo);
    return map;
  }

  ConfiguracionCompanion toCompanion(bool nullToAbsent) {
    return ConfiguracionCompanion(
      clave: Value(clave),
      valor: Value(valor),
      tipo: Value(tipo),
    );
  }

  factory ConfiguracionData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConfiguracionData(
      clave: serializer.fromJson<String>(json['clave']),
      valor: serializer.fromJson<String>(json['valor']),
      tipo: serializer.fromJson<String>(json['tipo']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'clave': serializer.toJson<String>(clave),
      'valor': serializer.toJson<String>(valor),
      'tipo': serializer.toJson<String>(tipo),
    };
  }

  ConfiguracionData copyWith({String? clave, String? valor, String? tipo}) =>
      ConfiguracionData(
        clave: clave ?? this.clave,
        valor: valor ?? this.valor,
        tipo: tipo ?? this.tipo,
      );
  ConfiguracionData copyWithCompanion(ConfiguracionCompanion data) {
    return ConfiguracionData(
      clave: data.clave.present ? data.clave.value : this.clave,
      valor: data.valor.present ? data.valor.value : this.valor,
      tipo: data.tipo.present ? data.tipo.value : this.tipo,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConfiguracionData(')
          ..write('clave: $clave, ')
          ..write('valor: $valor, ')
          ..write('tipo: $tipo')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(clave, valor, tipo);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConfiguracionData &&
          other.clave == this.clave &&
          other.valor == this.valor &&
          other.tipo == this.tipo);
}

class ConfiguracionCompanion extends UpdateCompanion<ConfiguracionData> {
  final Value<String> clave;
  final Value<String> valor;
  final Value<String> tipo;
  final Value<int> rowid;
  const ConfiguracionCompanion({
    this.clave = const Value.absent(),
    this.valor = const Value.absent(),
    this.tipo = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConfiguracionCompanion.insert({
    required String clave,
    required String valor,
    this.tipo = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : clave = Value(clave),
       valor = Value(valor);
  static Insertable<ConfiguracionData> custom({
    Expression<String>? clave,
    Expression<String>? valor,
    Expression<String>? tipo,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (clave != null) 'clave': clave,
      if (valor != null) 'valor': valor,
      if (tipo != null) 'tipo': tipo,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConfiguracionCompanion copyWith({
    Value<String>? clave,
    Value<String>? valor,
    Value<String>? tipo,
    Value<int>? rowid,
  }) {
    return ConfiguracionCompanion(
      clave: clave ?? this.clave,
      valor: valor ?? this.valor,
      tipo: tipo ?? this.tipo,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (clave.present) {
      map['clave'] = Variable<String>(clave.value);
    }
    if (valor.present) {
      map['valor'] = Variable<String>(valor.value);
    }
    if (tipo.present) {
      map['tipo'] = Variable<String>(tipo.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConfiguracionCompanion(')
          ..write('clave: $clave, ')
          ..write('valor: $valor, ')
          ..write('tipo: $tipo, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EstadoAppTable extends EstadoApp
    with TableInfo<$EstadoAppTable, EstadoAppData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EstadoAppTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _usuarioUuidMeta = const VerificationMeta(
    'usuarioUuid',
  );
  @override
  late final GeneratedColumn<String> usuarioUuid = GeneratedColumn<String>(
    'usuario_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dispositivoUuidMeta = const VerificationMeta(
    'dispositivoUuid',
  );
  @override
  late final GeneratedColumn<String> dispositivoUuid = GeneratedColumn<String>(
    'dispositivo_uuid',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _prefijoFolioMeta = const VerificationMeta(
    'prefijoFolio',
  );
  @override
  late final GeneratedColumn<String> prefijoFolio = GeneratedColumn<String>(
    'prefijo_folio',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _secuenciaFolioMeta = const VerificationMeta(
    'secuenciaFolio',
  );
  @override
  late final GeneratedColumn<int> secuenciaFolio = GeneratedColumn<int>(
    'secuencia_folio',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _offlineValidoHastaMeta =
      const VerificationMeta('offlineValidoHasta');
  @override
  late final GeneratedColumn<DateTime> offlineValidoHasta =
      GeneratedColumn<DateTime>(
        'offline_valido_hasta',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _ultimoSyncExitosoMeta = const VerificationMeta(
    'ultimoSyncExitoso',
  );
  @override
  late final GeneratedColumn<DateTime> ultimoSyncExitoso =
      GeneratedColumn<DateTime>(
        'ultimo_sync_exitoso',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    usuarioUuid,
    dispositivoUuid,
    prefijoFolio,
    secuenciaFolio,
    offlineValidoHasta,
    ultimoSyncExitoso,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'estado_app';
  @override
  VerificationContext validateIntegrity(
    Insertable<EstadoAppData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('usuario_uuid')) {
      context.handle(
        _usuarioUuidMeta,
        usuarioUuid.isAcceptableOrUnknown(
          data['usuario_uuid']!,
          _usuarioUuidMeta,
        ),
      );
    }
    if (data.containsKey('dispositivo_uuid')) {
      context.handle(
        _dispositivoUuidMeta,
        dispositivoUuid.isAcceptableOrUnknown(
          data['dispositivo_uuid']!,
          _dispositivoUuidMeta,
        ),
      );
    }
    if (data.containsKey('prefijo_folio')) {
      context.handle(
        _prefijoFolioMeta,
        prefijoFolio.isAcceptableOrUnknown(
          data['prefijo_folio']!,
          _prefijoFolioMeta,
        ),
      );
    }
    if (data.containsKey('secuencia_folio')) {
      context.handle(
        _secuenciaFolioMeta,
        secuenciaFolio.isAcceptableOrUnknown(
          data['secuencia_folio']!,
          _secuenciaFolioMeta,
        ),
      );
    }
    if (data.containsKey('offline_valido_hasta')) {
      context.handle(
        _offlineValidoHastaMeta,
        offlineValidoHasta.isAcceptableOrUnknown(
          data['offline_valido_hasta']!,
          _offlineValidoHastaMeta,
        ),
      );
    }
    if (data.containsKey('ultimo_sync_exitoso')) {
      context.handle(
        _ultimoSyncExitosoMeta,
        ultimoSyncExitoso.isAcceptableOrUnknown(
          data['ultimo_sync_exitoso']!,
          _ultimoSyncExitosoMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  EstadoAppData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EstadoAppData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      usuarioUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}usuario_uuid'],
      ),
      dispositivoUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dispositivo_uuid'],
      ),
      prefijoFolio: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prefijo_folio'],
      ),
      secuenciaFolio: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}secuencia_folio'],
      )!,
      offlineValidoHasta: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}offline_valido_hasta'],
      ),
      ultimoSyncExitoso: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ultimo_sync_exitoso'],
      ),
    );
  }

  @override
  $EstadoAppTable createAlias(String alias) {
    return $EstadoAppTable(attachedDatabase, alias);
  }
}

class EstadoAppData extends DataClass implements Insertable<EstadoAppData> {
  final int id;
  final String? usuarioUuid;
  final String? dispositivoUuid;

  /// Prefijo asignado por el servidor para numerar ventas sin colisionar con
  /// otras cajas: `A1-000042`.
  final String? prefijoFolio;
  final int secuenciaFolio;

  /// Hasta cuándo se puede operar sin volver a ver el servidor.
  final DateTime? offlineValidoHasta;
  final DateTime? ultimoSyncExitoso;
  const EstadoAppData({
    required this.id,
    this.usuarioUuid,
    this.dispositivoUuid,
    this.prefijoFolio,
    required this.secuenciaFolio,
    this.offlineValidoHasta,
    this.ultimoSyncExitoso,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || usuarioUuid != null) {
      map['usuario_uuid'] = Variable<String>(usuarioUuid);
    }
    if (!nullToAbsent || dispositivoUuid != null) {
      map['dispositivo_uuid'] = Variable<String>(dispositivoUuid);
    }
    if (!nullToAbsent || prefijoFolio != null) {
      map['prefijo_folio'] = Variable<String>(prefijoFolio);
    }
    map['secuencia_folio'] = Variable<int>(secuenciaFolio);
    if (!nullToAbsent || offlineValidoHasta != null) {
      map['offline_valido_hasta'] = Variable<DateTime>(offlineValidoHasta);
    }
    if (!nullToAbsent || ultimoSyncExitoso != null) {
      map['ultimo_sync_exitoso'] = Variable<DateTime>(ultimoSyncExitoso);
    }
    return map;
  }

  EstadoAppCompanion toCompanion(bool nullToAbsent) {
    return EstadoAppCompanion(
      id: Value(id),
      usuarioUuid: usuarioUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(usuarioUuid),
      dispositivoUuid: dispositivoUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(dispositivoUuid),
      prefijoFolio: prefijoFolio == null && nullToAbsent
          ? const Value.absent()
          : Value(prefijoFolio),
      secuenciaFolio: Value(secuenciaFolio),
      offlineValidoHasta: offlineValidoHasta == null && nullToAbsent
          ? const Value.absent()
          : Value(offlineValidoHasta),
      ultimoSyncExitoso: ultimoSyncExitoso == null && nullToAbsent
          ? const Value.absent()
          : Value(ultimoSyncExitoso),
    );
  }

  factory EstadoAppData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EstadoAppData(
      id: serializer.fromJson<int>(json['id']),
      usuarioUuid: serializer.fromJson<String?>(json['usuarioUuid']),
      dispositivoUuid: serializer.fromJson<String?>(json['dispositivoUuid']),
      prefijoFolio: serializer.fromJson<String?>(json['prefijoFolio']),
      secuenciaFolio: serializer.fromJson<int>(json['secuenciaFolio']),
      offlineValidoHasta: serializer.fromJson<DateTime?>(
        json['offlineValidoHasta'],
      ),
      ultimoSyncExitoso: serializer.fromJson<DateTime?>(
        json['ultimoSyncExitoso'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'usuarioUuid': serializer.toJson<String?>(usuarioUuid),
      'dispositivoUuid': serializer.toJson<String?>(dispositivoUuid),
      'prefijoFolio': serializer.toJson<String?>(prefijoFolio),
      'secuenciaFolio': serializer.toJson<int>(secuenciaFolio),
      'offlineValidoHasta': serializer.toJson<DateTime?>(offlineValidoHasta),
      'ultimoSyncExitoso': serializer.toJson<DateTime?>(ultimoSyncExitoso),
    };
  }

  EstadoAppData copyWith({
    int? id,
    Value<String?> usuarioUuid = const Value.absent(),
    Value<String?> dispositivoUuid = const Value.absent(),
    Value<String?> prefijoFolio = const Value.absent(),
    int? secuenciaFolio,
    Value<DateTime?> offlineValidoHasta = const Value.absent(),
    Value<DateTime?> ultimoSyncExitoso = const Value.absent(),
  }) => EstadoAppData(
    id: id ?? this.id,
    usuarioUuid: usuarioUuid.present ? usuarioUuid.value : this.usuarioUuid,
    dispositivoUuid: dispositivoUuid.present
        ? dispositivoUuid.value
        : this.dispositivoUuid,
    prefijoFolio: prefijoFolio.present ? prefijoFolio.value : this.prefijoFolio,
    secuenciaFolio: secuenciaFolio ?? this.secuenciaFolio,
    offlineValidoHasta: offlineValidoHasta.present
        ? offlineValidoHasta.value
        : this.offlineValidoHasta,
    ultimoSyncExitoso: ultimoSyncExitoso.present
        ? ultimoSyncExitoso.value
        : this.ultimoSyncExitoso,
  );
  EstadoAppData copyWithCompanion(EstadoAppCompanion data) {
    return EstadoAppData(
      id: data.id.present ? data.id.value : this.id,
      usuarioUuid: data.usuarioUuid.present
          ? data.usuarioUuid.value
          : this.usuarioUuid,
      dispositivoUuid: data.dispositivoUuid.present
          ? data.dispositivoUuid.value
          : this.dispositivoUuid,
      prefijoFolio: data.prefijoFolio.present
          ? data.prefijoFolio.value
          : this.prefijoFolio,
      secuenciaFolio: data.secuenciaFolio.present
          ? data.secuenciaFolio.value
          : this.secuenciaFolio,
      offlineValidoHasta: data.offlineValidoHasta.present
          ? data.offlineValidoHasta.value
          : this.offlineValidoHasta,
      ultimoSyncExitoso: data.ultimoSyncExitoso.present
          ? data.ultimoSyncExitoso.value
          : this.ultimoSyncExitoso,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EstadoAppData(')
          ..write('id: $id, ')
          ..write('usuarioUuid: $usuarioUuid, ')
          ..write('dispositivoUuid: $dispositivoUuid, ')
          ..write('prefijoFolio: $prefijoFolio, ')
          ..write('secuenciaFolio: $secuenciaFolio, ')
          ..write('offlineValidoHasta: $offlineValidoHasta, ')
          ..write('ultimoSyncExitoso: $ultimoSyncExitoso')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    usuarioUuid,
    dispositivoUuid,
    prefijoFolio,
    secuenciaFolio,
    offlineValidoHasta,
    ultimoSyncExitoso,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EstadoAppData &&
          other.id == this.id &&
          other.usuarioUuid == this.usuarioUuid &&
          other.dispositivoUuid == this.dispositivoUuid &&
          other.prefijoFolio == this.prefijoFolio &&
          other.secuenciaFolio == this.secuenciaFolio &&
          other.offlineValidoHasta == this.offlineValidoHasta &&
          other.ultimoSyncExitoso == this.ultimoSyncExitoso);
}

class EstadoAppCompanion extends UpdateCompanion<EstadoAppData> {
  final Value<int> id;
  final Value<String?> usuarioUuid;
  final Value<String?> dispositivoUuid;
  final Value<String?> prefijoFolio;
  final Value<int> secuenciaFolio;
  final Value<DateTime?> offlineValidoHasta;
  final Value<DateTime?> ultimoSyncExitoso;
  const EstadoAppCompanion({
    this.id = const Value.absent(),
    this.usuarioUuid = const Value.absent(),
    this.dispositivoUuid = const Value.absent(),
    this.prefijoFolio = const Value.absent(),
    this.secuenciaFolio = const Value.absent(),
    this.offlineValidoHasta = const Value.absent(),
    this.ultimoSyncExitoso = const Value.absent(),
  });
  EstadoAppCompanion.insert({
    this.id = const Value.absent(),
    this.usuarioUuid = const Value.absent(),
    this.dispositivoUuid = const Value.absent(),
    this.prefijoFolio = const Value.absent(),
    this.secuenciaFolio = const Value.absent(),
    this.offlineValidoHasta = const Value.absent(),
    this.ultimoSyncExitoso = const Value.absent(),
  });
  static Insertable<EstadoAppData> custom({
    Expression<int>? id,
    Expression<String>? usuarioUuid,
    Expression<String>? dispositivoUuid,
    Expression<String>? prefijoFolio,
    Expression<int>? secuenciaFolio,
    Expression<DateTime>? offlineValidoHasta,
    Expression<DateTime>? ultimoSyncExitoso,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (usuarioUuid != null) 'usuario_uuid': usuarioUuid,
      if (dispositivoUuid != null) 'dispositivo_uuid': dispositivoUuid,
      if (prefijoFolio != null) 'prefijo_folio': prefijoFolio,
      if (secuenciaFolio != null) 'secuencia_folio': secuenciaFolio,
      if (offlineValidoHasta != null)
        'offline_valido_hasta': offlineValidoHasta,
      if (ultimoSyncExitoso != null) 'ultimo_sync_exitoso': ultimoSyncExitoso,
    });
  }

  EstadoAppCompanion copyWith({
    Value<int>? id,
    Value<String?>? usuarioUuid,
    Value<String?>? dispositivoUuid,
    Value<String?>? prefijoFolio,
    Value<int>? secuenciaFolio,
    Value<DateTime?>? offlineValidoHasta,
    Value<DateTime?>? ultimoSyncExitoso,
  }) {
    return EstadoAppCompanion(
      id: id ?? this.id,
      usuarioUuid: usuarioUuid ?? this.usuarioUuid,
      dispositivoUuid: dispositivoUuid ?? this.dispositivoUuid,
      prefijoFolio: prefijoFolio ?? this.prefijoFolio,
      secuenciaFolio: secuenciaFolio ?? this.secuenciaFolio,
      offlineValidoHasta: offlineValidoHasta ?? this.offlineValidoHasta,
      ultimoSyncExitoso: ultimoSyncExitoso ?? this.ultimoSyncExitoso,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (usuarioUuid.present) {
      map['usuario_uuid'] = Variable<String>(usuarioUuid.value);
    }
    if (dispositivoUuid.present) {
      map['dispositivo_uuid'] = Variable<String>(dispositivoUuid.value);
    }
    if (prefijoFolio.present) {
      map['prefijo_folio'] = Variable<String>(prefijoFolio.value);
    }
    if (secuenciaFolio.present) {
      map['secuencia_folio'] = Variable<int>(secuenciaFolio.value);
    }
    if (offlineValidoHasta.present) {
      map['offline_valido_hasta'] = Variable<DateTime>(
        offlineValidoHasta.value,
      );
    }
    if (ultimoSyncExitoso.present) {
      map['ultimo_sync_exitoso'] = Variable<DateTime>(ultimoSyncExitoso.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EstadoAppCompanion(')
          ..write('id: $id, ')
          ..write('usuarioUuid: $usuarioUuid, ')
          ..write('dispositivoUuid: $dispositivoUuid, ')
          ..write('prefijoFolio: $prefijoFolio, ')
          ..write('secuenciaFolio: $secuenciaFolio, ')
          ..write('offlineValidoHasta: $offlineValidoHasta, ')
          ..write('ultimoSyncExitoso: $ultimoSyncExitoso')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $UsuariosTable usuarios = $UsuariosTable(this);
  late final $CategoriasTable categorias = $CategoriasTable(this);
  late final $ProveedoresTable proveedores = $ProveedoresTable(this);
  late final $ProductosTable productos = $ProductosTable(this);
  late final $ProductoCodigosTable productoCodigos = $ProductoCodigosTable(
    this,
  );
  late final $VentasTable ventas = $VentasTable(this);
  late final $VentaDetallesTable ventaDetalles = $VentaDetallesTable(this);
  late final $MovimientosTable movimientos = $MovimientosTable(this);
  late final $AlertasTable alertas = $AlertasTable(this);
  late final $SyncOutboxTable syncOutbox = $SyncOutboxTable(this);
  late final $SyncCursoresTable syncCursores = $SyncCursoresTable(this);
  late final $ConfiguracionTable configuracion = $ConfiguracionTable(this);
  late final $EstadoAppTable estadoApp = $EstadoAppTable(this);
  late final Index idxProductosNombre = Index(
    'idx_productos_nombre',
    'CREATE INDEX idx_productos_nombre ON productos (nombre)',
  );
  late final Index idxProductosSku = Index(
    'idx_productos_sku',
    'CREATE INDEX idx_productos_sku ON productos (sku)',
  );
  late final Index idxProductosStock = Index(
    'idx_productos_stock',
    'CREATE INDEX idx_productos_stock ON productos (stock_actual)',
  );
  late final Index idxCodigosCodigo = Index(
    'idx_codigos_codigo',
    'CREATE UNIQUE INDEX idx_codigos_codigo ON producto_codigos (codigo)',
  );
  late final Index idxVentasFecha = Index(
    'idx_ventas_fecha',
    'CREATE INDEX idx_ventas_fecha ON ventas (fecha_local)',
  );
  late final Index idxVentasPendiente = Index(
    'idx_ventas_pendiente',
    'CREATE INDEX idx_ventas_pendiente ON ventas (sincronizada_en)',
  );
  late final Index idxDetallesVenta = Index(
    'idx_detalles_venta',
    'CREATE INDEX idx_detalles_venta ON venta_detalles (venta_uuid)',
  );
  late final Index idxMovProducto = Index(
    'idx_mov_producto',
    'CREATE INDEX idx_mov_producto ON movimientos (producto_uuid)',
  );
  late final Index idxMovFecha = Index(
    'idx_mov_fecha',
    'CREATE INDEX idx_mov_fecha ON movimientos (fecha_local)',
  );
  late final Index idxOutboxPendientes = Index(
    'idx_outbox_pendientes',
    'CREATE INDEX idx_outbox_pendientes ON sync_outbox (estado, proximo_intento)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    usuarios,
    categorias,
    proveedores,
    productos,
    productoCodigos,
    ventas,
    ventaDetalles,
    movimientos,
    alertas,
    syncOutbox,
    syncCursores,
    configuracion,
    estadoApp,
    idxProductosNombre,
    idxProductosSku,
    idxProductosStock,
    idxCodigosCodigo,
    idxVentasFecha,
    idxVentasPendiente,
    idxDetallesVenta,
    idxMovProducto,
    idxMovFecha,
    idxOutboxPendientes,
  ];
}

typedef $$UsuariosTableCreateCompanionBuilder =
    UsuariosCompanion Function({
      required String uuid,
      required String nombre,
      required String email,
      Value<String> rol,
      Value<bool> activo,
      Value<String?> passwordHashLocal,
      Value<String?> saltLocal,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$UsuariosTableUpdateCompanionBuilder =
    UsuariosCompanion Function({
      Value<String> uuid,
      Value<String> nombre,
      Value<String> email,
      Value<String> rol,
      Value<bool> activo,
      Value<String?> passwordHashLocal,
      Value<String?> saltLocal,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$UsuariosTableFilterComposer
    extends Composer<_$AppDatabase, $UsuariosTable> {
  $$UsuariosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rol => $composableBuilder(
    column: $table.rol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get passwordHashLocal => $composableBuilder(
    column: $table.passwordHashLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get saltLocal => $composableBuilder(
    column: $table.saltLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsuariosTableOrderingComposer
    extends Composer<_$AppDatabase, $UsuariosTable> {
  $$UsuariosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rol => $composableBuilder(
    column: $table.rol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get passwordHashLocal => $composableBuilder(
    column: $table.passwordHashLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get saltLocal => $composableBuilder(
    column: $table.saltLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsuariosTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsuariosTable> {
  $$UsuariosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get rol =>
      $composableBuilder(column: $table.rol, builder: (column) => column);

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);

  GeneratedColumn<String> get passwordHashLocal => $composableBuilder(
    column: $table.passwordHashLocal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get saltLocal =>
      $composableBuilder(column: $table.saltLocal, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$UsuariosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsuariosTable,
          Usuario,
          $$UsuariosTableFilterComposer,
          $$UsuariosTableOrderingComposer,
          $$UsuariosTableAnnotationComposer,
          $$UsuariosTableCreateCompanionBuilder,
          $$UsuariosTableUpdateCompanionBuilder,
          (Usuario, BaseReferences<_$AppDatabase, $UsuariosTable, Usuario>),
          Usuario,
          PrefetchHooks Function()
        > {
  $$UsuariosTableTableManager(_$AppDatabase db, $UsuariosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsuariosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsuariosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsuariosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> rol = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<String?> passwordHashLocal = const Value.absent(),
                Value<String?> saltLocal = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsuariosCompanion(
                uuid: uuid,
                nombre: nombre,
                email: email,
                rol: rol,
                activo: activo,
                passwordHashLocal: passwordHashLocal,
                saltLocal: saltLocal,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uuid,
                required String nombre,
                required String email,
                Value<String> rol = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<String?> passwordHashLocal = const Value.absent(),
                Value<String?> saltLocal = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsuariosCompanion.insert(
                uuid: uuid,
                nombre: nombre,
                email: email,
                rol: rol,
                activo: activo,
                passwordHashLocal: passwordHashLocal,
                saltLocal: saltLocal,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsuariosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsuariosTable,
      Usuario,
      $$UsuariosTableFilterComposer,
      $$UsuariosTableOrderingComposer,
      $$UsuariosTableAnnotationComposer,
      $$UsuariosTableCreateCompanionBuilder,
      $$UsuariosTableUpdateCompanionBuilder,
      (Usuario, BaseReferences<_$AppDatabase, $UsuariosTable, Usuario>),
      Usuario,
      PrefetchHooks Function()
    >;
typedef $$CategoriasTableCreateCompanionBuilder =
    CategoriasCompanion Function({
      required String uuid,
      required String nombre,
      Value<String?> descripcion,
      Value<String> color,
      Value<String?> icono,
      Value<int> orden,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$CategoriasTableUpdateCompanionBuilder =
    CategoriasCompanion Function({
      Value<String> uuid,
      Value<String> nombre,
      Value<String?> descripcion,
      Value<String> color,
      Value<String?> icono,
      Value<int> orden,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$CategoriasTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriasTable> {
  $$CategoriasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icono => $composableBuilder(
    column: $table.icono,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get orden => $composableBuilder(
    column: $table.orden,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CategoriasTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriasTable> {
  $$CategoriasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icono => $composableBuilder(
    column: $table.icono,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get orden => $composableBuilder(
    column: $table.orden,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriasTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriasTable> {
  $$CategoriasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get icono =>
      $composableBuilder(column: $table.icono, builder: (column) => column);

  GeneratedColumn<int> get orden =>
      $composableBuilder(column: $table.orden, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$CategoriasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriasTable,
          Categoria,
          $$CategoriasTableFilterComposer,
          $$CategoriasTableOrderingComposer,
          $$CategoriasTableAnnotationComposer,
          $$CategoriasTableCreateCompanionBuilder,
          $$CategoriasTableUpdateCompanionBuilder,
          (
            Categoria,
            BaseReferences<_$AppDatabase, $CategoriasTable, Categoria>,
          ),
          Categoria,
          PrefetchHooks Function()
        > {
  $$CategoriasTableTableManager(_$AppDatabase db, $CategoriasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String?> descripcion = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<String?> icono = const Value.absent(),
                Value<int> orden = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriasCompanion(
                uuid: uuid,
                nombre: nombre,
                descripcion: descripcion,
                color: color,
                icono: icono,
                orden: orden,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uuid,
                required String nombre,
                Value<String?> descripcion = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<String?> icono = const Value.absent(),
                Value<int> orden = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriasCompanion.insert(
                uuid: uuid,
                nombre: nombre,
                descripcion: descripcion,
                color: color,
                icono: icono,
                orden: orden,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CategoriasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriasTable,
      Categoria,
      $$CategoriasTableFilterComposer,
      $$CategoriasTableOrderingComposer,
      $$CategoriasTableAnnotationComposer,
      $$CategoriasTableCreateCompanionBuilder,
      $$CategoriasTableUpdateCompanionBuilder,
      (Categoria, BaseReferences<_$AppDatabase, $CategoriasTable, Categoria>),
      Categoria,
      PrefetchHooks Function()
    >;
typedef $$ProveedoresTableCreateCompanionBuilder =
    ProveedoresCompanion Function({
      required String uuid,
      required String nombre,
      Value<String?> nit,
      Value<String?> contacto,
      Value<String?> telefono,
      Value<String?> email,
      Value<String?> direccion,
      Value<String?> notas,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$ProveedoresTableUpdateCompanionBuilder =
    ProveedoresCompanion Function({
      Value<String> uuid,
      Value<String> nombre,
      Value<String?> nit,
      Value<String?> contacto,
      Value<String?> telefono,
      Value<String?> email,
      Value<String?> direccion,
      Value<String?> notas,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$ProveedoresTableFilterComposer
    extends Composer<_$AppDatabase, $ProveedoresTable> {
  $$ProveedoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nit => $composableBuilder(
    column: $table.nit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contacto => $composableBuilder(
    column: $table.contacto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get telefono => $composableBuilder(
    column: $table.telefono,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get direccion => $composableBuilder(
    column: $table.direccion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notas => $composableBuilder(
    column: $table.notas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProveedoresTableOrderingComposer
    extends Composer<_$AppDatabase, $ProveedoresTable> {
  $$ProveedoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nit => $composableBuilder(
    column: $table.nit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contacto => $composableBuilder(
    column: $table.contacto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get telefono => $composableBuilder(
    column: $table.telefono,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get direccion => $composableBuilder(
    column: $table.direccion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notas => $composableBuilder(
    column: $table.notas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProveedoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProveedoresTable> {
  $$ProveedoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get nit =>
      $composableBuilder(column: $table.nit, builder: (column) => column);

  GeneratedColumn<String> get contacto =>
      $composableBuilder(column: $table.contacto, builder: (column) => column);

  GeneratedColumn<String> get telefono =>
      $composableBuilder(column: $table.telefono, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get direccion =>
      $composableBuilder(column: $table.direccion, builder: (column) => column);

  GeneratedColumn<String> get notas =>
      $composableBuilder(column: $table.notas, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$ProveedoresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProveedoresTable,
          Proveedor,
          $$ProveedoresTableFilterComposer,
          $$ProveedoresTableOrderingComposer,
          $$ProveedoresTableAnnotationComposer,
          $$ProveedoresTableCreateCompanionBuilder,
          $$ProveedoresTableUpdateCompanionBuilder,
          (
            Proveedor,
            BaseReferences<_$AppDatabase, $ProveedoresTable, Proveedor>,
          ),
          Proveedor,
          PrefetchHooks Function()
        > {
  $$ProveedoresTableTableManager(_$AppDatabase db, $ProveedoresTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProveedoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProveedoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProveedoresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String?> nit = const Value.absent(),
                Value<String?> contacto = const Value.absent(),
                Value<String?> telefono = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> direccion = const Value.absent(),
                Value<String?> notas = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProveedoresCompanion(
                uuid: uuid,
                nombre: nombre,
                nit: nit,
                contacto: contacto,
                telefono: telefono,
                email: email,
                direccion: direccion,
                notas: notas,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uuid,
                required String nombre,
                Value<String?> nit = const Value.absent(),
                Value<String?> contacto = const Value.absent(),
                Value<String?> telefono = const Value.absent(),
                Value<String?> email = const Value.absent(),
                Value<String?> direccion = const Value.absent(),
                Value<String?> notas = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProveedoresCompanion.insert(
                uuid: uuid,
                nombre: nombre,
                nit: nit,
                contacto: contacto,
                telefono: telefono,
                email: email,
                direccion: direccion,
                notas: notas,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProveedoresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProveedoresTable,
      Proveedor,
      $$ProveedoresTableFilterComposer,
      $$ProveedoresTableOrderingComposer,
      $$ProveedoresTableAnnotationComposer,
      $$ProveedoresTableCreateCompanionBuilder,
      $$ProveedoresTableUpdateCompanionBuilder,
      (Proveedor, BaseReferences<_$AppDatabase, $ProveedoresTable, Proveedor>),
      Proveedor,
      PrefetchHooks Function()
    >;
typedef $$ProductosTableCreateCompanionBuilder =
    ProductosCompanion Function({
      required String uuid,
      required String sku,
      required String nombre,
      Value<String> nombreBusqueda,
      Value<String?> descripcion,
      Value<String?> categoriaUuid,
      Value<String> unidadMedida,
      Value<int> precioCompra,
      Value<int> precioVenta,
      Value<int> tasaIva,
      Value<int> stockActual,
      Value<int> stockMinimo,
      Value<int?> stockMaximo,
      Value<String?> imagenUrl,
      Value<String?> imagenLocal,
      Value<String?> ubicacion,
      Value<bool> activo,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$ProductosTableUpdateCompanionBuilder =
    ProductosCompanion Function({
      Value<String> uuid,
      Value<String> sku,
      Value<String> nombre,
      Value<String> nombreBusqueda,
      Value<String?> descripcion,
      Value<String?> categoriaUuid,
      Value<String> unidadMedida,
      Value<int> precioCompra,
      Value<int> precioVenta,
      Value<int> tasaIva,
      Value<int> stockActual,
      Value<int> stockMinimo,
      Value<int?> stockMaximo,
      Value<String?> imagenUrl,
      Value<String?> imagenLocal,
      Value<String?> ubicacion,
      Value<bool> activo,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$ProductosTableFilterComposer
    extends Composer<_$AppDatabase, $ProductosTable> {
  $$ProductosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nombreBusqueda => $composableBuilder(
    column: $table.nombreBusqueda,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoriaUuid => $composableBuilder(
    column: $table.categoriaUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unidadMedida => $composableBuilder(
    column: $table.unidadMedida,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get precioCompra => $composableBuilder(
    column: $table.precioCompra,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get precioVenta => $composableBuilder(
    column: $table.precioVenta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tasaIva => $composableBuilder(
    column: $table.tasaIva,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stockActual => $composableBuilder(
    column: $table.stockActual,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stockMinimo => $composableBuilder(
    column: $table.stockMinimo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stockMaximo => $composableBuilder(
    column: $table.stockMaximo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagenUrl => $composableBuilder(
    column: $table.imagenUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagenLocal => $composableBuilder(
    column: $table.imagenLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ubicacion => $composableBuilder(
    column: $table.ubicacion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductosTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductosTable> {
  $$ProductosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sku => $composableBuilder(
    column: $table.sku,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombre => $composableBuilder(
    column: $table.nombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nombreBusqueda => $composableBuilder(
    column: $table.nombreBusqueda,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoriaUuid => $composableBuilder(
    column: $table.categoriaUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unidadMedida => $composableBuilder(
    column: $table.unidadMedida,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get precioCompra => $composableBuilder(
    column: $table.precioCompra,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get precioVenta => $composableBuilder(
    column: $table.precioVenta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tasaIva => $composableBuilder(
    column: $table.tasaIva,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stockActual => $composableBuilder(
    column: $table.stockActual,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stockMinimo => $composableBuilder(
    column: $table.stockMinimo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stockMaximo => $composableBuilder(
    column: $table.stockMaximo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagenUrl => $composableBuilder(
    column: $table.imagenUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagenLocal => $composableBuilder(
    column: $table.imagenLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ubicacion => $composableBuilder(
    column: $table.ubicacion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get activo => $composableBuilder(
    column: $table.activo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductosTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductosTable> {
  $$ProductosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get sku =>
      $composableBuilder(column: $table.sku, builder: (column) => column);

  GeneratedColumn<String> get nombre =>
      $composableBuilder(column: $table.nombre, builder: (column) => column);

  GeneratedColumn<String> get nombreBusqueda => $composableBuilder(
    column: $table.nombreBusqueda,
    builder: (column) => column,
  );

  GeneratedColumn<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get categoriaUuid => $composableBuilder(
    column: $table.categoriaUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unidadMedida => $composableBuilder(
    column: $table.unidadMedida,
    builder: (column) => column,
  );

  GeneratedColumn<int> get precioCompra => $composableBuilder(
    column: $table.precioCompra,
    builder: (column) => column,
  );

  GeneratedColumn<int> get precioVenta => $composableBuilder(
    column: $table.precioVenta,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tasaIva =>
      $composableBuilder(column: $table.tasaIva, builder: (column) => column);

  GeneratedColumn<int> get stockActual => $composableBuilder(
    column: $table.stockActual,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stockMinimo => $composableBuilder(
    column: $table.stockMinimo,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stockMaximo => $composableBuilder(
    column: $table.stockMaximo,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imagenUrl =>
      $composableBuilder(column: $table.imagenUrl, builder: (column) => column);

  GeneratedColumn<String> get imagenLocal => $composableBuilder(
    column: $table.imagenLocal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ubicacion =>
      $composableBuilder(column: $table.ubicacion, builder: (column) => column);

  GeneratedColumn<bool> get activo =>
      $composableBuilder(column: $table.activo, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$ProductosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductosTable,
          Producto,
          $$ProductosTableFilterComposer,
          $$ProductosTableOrderingComposer,
          $$ProductosTableAnnotationComposer,
          $$ProductosTableCreateCompanionBuilder,
          $$ProductosTableUpdateCompanionBuilder,
          (Producto, BaseReferences<_$AppDatabase, $ProductosTable, Producto>),
          Producto,
          PrefetchHooks Function()
        > {
  $$ProductosTableTableManager(_$AppDatabase db, $ProductosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<String> sku = const Value.absent(),
                Value<String> nombre = const Value.absent(),
                Value<String> nombreBusqueda = const Value.absent(),
                Value<String?> descripcion = const Value.absent(),
                Value<String?> categoriaUuid = const Value.absent(),
                Value<String> unidadMedida = const Value.absent(),
                Value<int> precioCompra = const Value.absent(),
                Value<int> precioVenta = const Value.absent(),
                Value<int> tasaIva = const Value.absent(),
                Value<int> stockActual = const Value.absent(),
                Value<int> stockMinimo = const Value.absent(),
                Value<int?> stockMaximo = const Value.absent(),
                Value<String?> imagenUrl = const Value.absent(),
                Value<String?> imagenLocal = const Value.absent(),
                Value<String?> ubicacion = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductosCompanion(
                uuid: uuid,
                sku: sku,
                nombre: nombre,
                nombreBusqueda: nombreBusqueda,
                descripcion: descripcion,
                categoriaUuid: categoriaUuid,
                unidadMedida: unidadMedida,
                precioCompra: precioCompra,
                precioVenta: precioVenta,
                tasaIva: tasaIva,
                stockActual: stockActual,
                stockMinimo: stockMinimo,
                stockMaximo: stockMaximo,
                imagenUrl: imagenUrl,
                imagenLocal: imagenLocal,
                ubicacion: ubicacion,
                activo: activo,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uuid,
                required String sku,
                required String nombre,
                Value<String> nombreBusqueda = const Value.absent(),
                Value<String?> descripcion = const Value.absent(),
                Value<String?> categoriaUuid = const Value.absent(),
                Value<String> unidadMedida = const Value.absent(),
                Value<int> precioCompra = const Value.absent(),
                Value<int> precioVenta = const Value.absent(),
                Value<int> tasaIva = const Value.absent(),
                Value<int> stockActual = const Value.absent(),
                Value<int> stockMinimo = const Value.absent(),
                Value<int?> stockMaximo = const Value.absent(),
                Value<String?> imagenUrl = const Value.absent(),
                Value<String?> imagenLocal = const Value.absent(),
                Value<String?> ubicacion = const Value.absent(),
                Value<bool> activo = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductosCompanion.insert(
                uuid: uuid,
                sku: sku,
                nombre: nombre,
                nombreBusqueda: nombreBusqueda,
                descripcion: descripcion,
                categoriaUuid: categoriaUuid,
                unidadMedida: unidadMedida,
                precioCompra: precioCompra,
                precioVenta: precioVenta,
                tasaIva: tasaIva,
                stockActual: stockActual,
                stockMinimo: stockMinimo,
                stockMaximo: stockMaximo,
                imagenUrl: imagenUrl,
                imagenLocal: imagenLocal,
                ubicacion: ubicacion,
                activo: activo,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductosTable,
      Producto,
      $$ProductosTableFilterComposer,
      $$ProductosTableOrderingComposer,
      $$ProductosTableAnnotationComposer,
      $$ProductosTableCreateCompanionBuilder,
      $$ProductosTableUpdateCompanionBuilder,
      (Producto, BaseReferences<_$AppDatabase, $ProductosTable, Producto>),
      Producto,
      PrefetchHooks Function()
    >;
typedef $$ProductoCodigosTableCreateCompanionBuilder =
    ProductoCodigosCompanion Function({
      required String uuid,
      required String productoUuid,
      required String codigo,
      Value<String> tipo,
      Value<bool> esPrincipal,
      Value<int> factor,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$ProductoCodigosTableUpdateCompanionBuilder =
    ProductoCodigosCompanion Function({
      Value<String> uuid,
      Value<String> productoUuid,
      Value<String> codigo,
      Value<String> tipo,
      Value<bool> esPrincipal,
      Value<int> factor,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$ProductoCodigosTableFilterComposer
    extends Composer<_$AppDatabase, $ProductoCodigosTable> {
  $$ProductoCodigosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productoUuid => $composableBuilder(
    column: $table.productoUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codigo => $composableBuilder(
    column: $table.codigo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get esPrincipal => $composableBuilder(
    column: $table.esPrincipal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get factor => $composableBuilder(
    column: $table.factor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductoCodigosTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductoCodigosTable> {
  $$ProductoCodigosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productoUuid => $composableBuilder(
    column: $table.productoUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codigo => $composableBuilder(
    column: $table.codigo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get esPrincipal => $composableBuilder(
    column: $table.esPrincipal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get factor => $composableBuilder(
    column: $table.factor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductoCodigosTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductoCodigosTable> {
  $$ProductoCodigosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get productoUuid => $composableBuilder(
    column: $table.productoUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get codigo =>
      $composableBuilder(column: $table.codigo, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<bool> get esPrincipal => $composableBuilder(
    column: $table.esPrincipal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get factor =>
      $composableBuilder(column: $table.factor, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$ProductoCodigosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductoCodigosTable,
          ProductoCodigo,
          $$ProductoCodigosTableFilterComposer,
          $$ProductoCodigosTableOrderingComposer,
          $$ProductoCodigosTableAnnotationComposer,
          $$ProductoCodigosTableCreateCompanionBuilder,
          $$ProductoCodigosTableUpdateCompanionBuilder,
          (
            ProductoCodigo,
            BaseReferences<
              _$AppDatabase,
              $ProductoCodigosTable,
              ProductoCodigo
            >,
          ),
          ProductoCodigo,
          PrefetchHooks Function()
        > {
  $$ProductoCodigosTableTableManager(
    _$AppDatabase db,
    $ProductoCodigosTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductoCodigosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductoCodigosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductoCodigosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<String> productoUuid = const Value.absent(),
                Value<String> codigo = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<bool> esPrincipal = const Value.absent(),
                Value<int> factor = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductoCodigosCompanion(
                uuid: uuid,
                productoUuid: productoUuid,
                codigo: codigo,
                tipo: tipo,
                esPrincipal: esPrincipal,
                factor: factor,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uuid,
                required String productoUuid,
                required String codigo,
                Value<String> tipo = const Value.absent(),
                Value<bool> esPrincipal = const Value.absent(),
                Value<int> factor = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductoCodigosCompanion.insert(
                uuid: uuid,
                productoUuid: productoUuid,
                codigo: codigo,
                tipo: tipo,
                esPrincipal: esPrincipal,
                factor: factor,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductoCodigosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductoCodigosTable,
      ProductoCodigo,
      $$ProductoCodigosTableFilterComposer,
      $$ProductoCodigosTableOrderingComposer,
      $$ProductoCodigosTableAnnotationComposer,
      $$ProductoCodigosTableCreateCompanionBuilder,
      $$ProductoCodigosTableUpdateCompanionBuilder,
      (
        ProductoCodigo,
        BaseReferences<_$AppDatabase, $ProductoCodigosTable, ProductoCodigo>,
      ),
      ProductoCodigo,
      PrefetchHooks Function()
    >;
typedef $$VentasTableCreateCompanionBuilder =
    VentasCompanion Function({
      required String uuid,
      required String numero,
      Value<String?> usuarioUuid,
      Value<String?> dispositivoUuid,
      Value<String?> clienteNombre,
      Value<String?> clienteDocumento,
      Value<int> subtotal,
      Value<int> descuentoTotal,
      Value<int> impuestoTotal,
      Value<int> total,
      Value<int> costoTotal,
      Value<String> metodoPago,
      Value<int?> montoRecibido,
      Value<int?> cambio,
      Value<String> estado,
      Value<String?> anulaAVentaUuid,
      Value<String?> motivoAnulacion,
      Value<String?> notas,
      required DateTime fecha,
      required String fechaLocal,
      Value<bool> creadaOffline,
      Value<DateTime?> sincronizadaEn,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$VentasTableUpdateCompanionBuilder =
    VentasCompanion Function({
      Value<String> uuid,
      Value<String> numero,
      Value<String?> usuarioUuid,
      Value<String?> dispositivoUuid,
      Value<String?> clienteNombre,
      Value<String?> clienteDocumento,
      Value<int> subtotal,
      Value<int> descuentoTotal,
      Value<int> impuestoTotal,
      Value<int> total,
      Value<int> costoTotal,
      Value<String> metodoPago,
      Value<int?> montoRecibido,
      Value<int?> cambio,
      Value<String> estado,
      Value<String?> anulaAVentaUuid,
      Value<String?> motivoAnulacion,
      Value<String?> notas,
      Value<DateTime> fecha,
      Value<String> fechaLocal,
      Value<bool> creadaOffline,
      Value<DateTime?> sincronizadaEn,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$VentasTableFilterComposer
    extends Composer<_$AppDatabase, $VentasTable> {
  $$VentasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get numero => $composableBuilder(
    column: $table.numero,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get usuarioUuid => $composableBuilder(
    column: $table.usuarioUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dispositivoUuid => $composableBuilder(
    column: $table.dispositivoUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clienteNombre => $composableBuilder(
    column: $table.clienteNombre,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clienteDocumento => $composableBuilder(
    column: $table.clienteDocumento,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get descuentoTotal => $composableBuilder(
    column: $table.descuentoTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get impuestoTotal => $composableBuilder(
    column: $table.impuestoTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get costoTotal => $composableBuilder(
    column: $table.costoTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metodoPago => $composableBuilder(
    column: $table.metodoPago,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get montoRecibido => $composableBuilder(
    column: $table.montoRecibido,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cambio => $composableBuilder(
    column: $table.cambio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get anulaAVentaUuid => $composableBuilder(
    column: $table.anulaAVentaUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get motivoAnulacion => $composableBuilder(
    column: $table.motivoAnulacion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notas => $composableBuilder(
    column: $table.notas,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fechaLocal => $composableBuilder(
    column: $table.fechaLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get creadaOffline => $composableBuilder(
    column: $table.creadaOffline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sincronizadaEn => $composableBuilder(
    column: $table.sincronizadaEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VentasTableOrderingComposer
    extends Composer<_$AppDatabase, $VentasTable> {
  $$VentasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get numero => $composableBuilder(
    column: $table.numero,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get usuarioUuid => $composableBuilder(
    column: $table.usuarioUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dispositivoUuid => $composableBuilder(
    column: $table.dispositivoUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clienteNombre => $composableBuilder(
    column: $table.clienteNombre,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clienteDocumento => $composableBuilder(
    column: $table.clienteDocumento,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get subtotal => $composableBuilder(
    column: $table.subtotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get descuentoTotal => $composableBuilder(
    column: $table.descuentoTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get impuestoTotal => $composableBuilder(
    column: $table.impuestoTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get costoTotal => $composableBuilder(
    column: $table.costoTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metodoPago => $composableBuilder(
    column: $table.metodoPago,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get montoRecibido => $composableBuilder(
    column: $table.montoRecibido,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cambio => $composableBuilder(
    column: $table.cambio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get anulaAVentaUuid => $composableBuilder(
    column: $table.anulaAVentaUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get motivoAnulacion => $composableBuilder(
    column: $table.motivoAnulacion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notas => $composableBuilder(
    column: $table.notas,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fechaLocal => $composableBuilder(
    column: $table.fechaLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get creadaOffline => $composableBuilder(
    column: $table.creadaOffline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sincronizadaEn => $composableBuilder(
    column: $table.sincronizadaEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VentasTableAnnotationComposer
    extends Composer<_$AppDatabase, $VentasTable> {
  $$VentasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get numero =>
      $composableBuilder(column: $table.numero, builder: (column) => column);

  GeneratedColumn<String> get usuarioUuid => $composableBuilder(
    column: $table.usuarioUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dispositivoUuid => $composableBuilder(
    column: $table.dispositivoUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clienteNombre => $composableBuilder(
    column: $table.clienteNombre,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clienteDocumento => $composableBuilder(
    column: $table.clienteDocumento,
    builder: (column) => column,
  );

  GeneratedColumn<int> get subtotal =>
      $composableBuilder(column: $table.subtotal, builder: (column) => column);

  GeneratedColumn<int> get descuentoTotal => $composableBuilder(
    column: $table.descuentoTotal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get impuestoTotal => $composableBuilder(
    column: $table.impuestoTotal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);

  GeneratedColumn<int> get costoTotal => $composableBuilder(
    column: $table.costoTotal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metodoPago => $composableBuilder(
    column: $table.metodoPago,
    builder: (column) => column,
  );

  GeneratedColumn<int> get montoRecibido => $composableBuilder(
    column: $table.montoRecibido,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cambio =>
      $composableBuilder(column: $table.cambio, builder: (column) => column);

  GeneratedColumn<String> get estado =>
      $composableBuilder(column: $table.estado, builder: (column) => column);

  GeneratedColumn<String> get anulaAVentaUuid => $composableBuilder(
    column: $table.anulaAVentaUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get motivoAnulacion => $composableBuilder(
    column: $table.motivoAnulacion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notas =>
      $composableBuilder(column: $table.notas, builder: (column) => column);

  GeneratedColumn<DateTime> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  GeneratedColumn<String> get fechaLocal => $composableBuilder(
    column: $table.fechaLocal,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get creadaOffline => $composableBuilder(
    column: $table.creadaOffline,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get sincronizadaEn => $composableBuilder(
    column: $table.sincronizadaEn,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$VentasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VentasTable,
          Venta,
          $$VentasTableFilterComposer,
          $$VentasTableOrderingComposer,
          $$VentasTableAnnotationComposer,
          $$VentasTableCreateCompanionBuilder,
          $$VentasTableUpdateCompanionBuilder,
          (Venta, BaseReferences<_$AppDatabase, $VentasTable, Venta>),
          Venta,
          PrefetchHooks Function()
        > {
  $$VentasTableTableManager(_$AppDatabase db, $VentasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VentasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VentasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VentasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<String> numero = const Value.absent(),
                Value<String?> usuarioUuid = const Value.absent(),
                Value<String?> dispositivoUuid = const Value.absent(),
                Value<String?> clienteNombre = const Value.absent(),
                Value<String?> clienteDocumento = const Value.absent(),
                Value<int> subtotal = const Value.absent(),
                Value<int> descuentoTotal = const Value.absent(),
                Value<int> impuestoTotal = const Value.absent(),
                Value<int> total = const Value.absent(),
                Value<int> costoTotal = const Value.absent(),
                Value<String> metodoPago = const Value.absent(),
                Value<int?> montoRecibido = const Value.absent(),
                Value<int?> cambio = const Value.absent(),
                Value<String> estado = const Value.absent(),
                Value<String?> anulaAVentaUuid = const Value.absent(),
                Value<String?> motivoAnulacion = const Value.absent(),
                Value<String?> notas = const Value.absent(),
                Value<DateTime> fecha = const Value.absent(),
                Value<String> fechaLocal = const Value.absent(),
                Value<bool> creadaOffline = const Value.absent(),
                Value<DateTime?> sincronizadaEn = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VentasCompanion(
                uuid: uuid,
                numero: numero,
                usuarioUuid: usuarioUuid,
                dispositivoUuid: dispositivoUuid,
                clienteNombre: clienteNombre,
                clienteDocumento: clienteDocumento,
                subtotal: subtotal,
                descuentoTotal: descuentoTotal,
                impuestoTotal: impuestoTotal,
                total: total,
                costoTotal: costoTotal,
                metodoPago: metodoPago,
                montoRecibido: montoRecibido,
                cambio: cambio,
                estado: estado,
                anulaAVentaUuid: anulaAVentaUuid,
                motivoAnulacion: motivoAnulacion,
                notas: notas,
                fecha: fecha,
                fechaLocal: fechaLocal,
                creadaOffline: creadaOffline,
                sincronizadaEn: sincronizadaEn,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uuid,
                required String numero,
                Value<String?> usuarioUuid = const Value.absent(),
                Value<String?> dispositivoUuid = const Value.absent(),
                Value<String?> clienteNombre = const Value.absent(),
                Value<String?> clienteDocumento = const Value.absent(),
                Value<int> subtotal = const Value.absent(),
                Value<int> descuentoTotal = const Value.absent(),
                Value<int> impuestoTotal = const Value.absent(),
                Value<int> total = const Value.absent(),
                Value<int> costoTotal = const Value.absent(),
                Value<String> metodoPago = const Value.absent(),
                Value<int?> montoRecibido = const Value.absent(),
                Value<int?> cambio = const Value.absent(),
                Value<String> estado = const Value.absent(),
                Value<String?> anulaAVentaUuid = const Value.absent(),
                Value<String?> motivoAnulacion = const Value.absent(),
                Value<String?> notas = const Value.absent(),
                required DateTime fecha,
                required String fechaLocal,
                Value<bool> creadaOffline = const Value.absent(),
                Value<DateTime?> sincronizadaEn = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VentasCompanion.insert(
                uuid: uuid,
                numero: numero,
                usuarioUuid: usuarioUuid,
                dispositivoUuid: dispositivoUuid,
                clienteNombre: clienteNombre,
                clienteDocumento: clienteDocumento,
                subtotal: subtotal,
                descuentoTotal: descuentoTotal,
                impuestoTotal: impuestoTotal,
                total: total,
                costoTotal: costoTotal,
                metodoPago: metodoPago,
                montoRecibido: montoRecibido,
                cambio: cambio,
                estado: estado,
                anulaAVentaUuid: anulaAVentaUuid,
                motivoAnulacion: motivoAnulacion,
                notas: notas,
                fecha: fecha,
                fechaLocal: fechaLocal,
                creadaOffline: creadaOffline,
                sincronizadaEn: sincronizadaEn,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VentasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VentasTable,
      Venta,
      $$VentasTableFilterComposer,
      $$VentasTableOrderingComposer,
      $$VentasTableAnnotationComposer,
      $$VentasTableCreateCompanionBuilder,
      $$VentasTableUpdateCompanionBuilder,
      (Venta, BaseReferences<_$AppDatabase, $VentasTable, Venta>),
      Venta,
      PrefetchHooks Function()
    >;
typedef $$VentaDetallesTableCreateCompanionBuilder =
    VentaDetallesCompanion Function({
      required String uuid,
      required String ventaUuid,
      Value<String?> productoUuid,
      Value<int> linea,
      required String descripcion,
      Value<String?> skuSnapshot,
      required int cantidad,
      required int precioUnitario,
      Value<int> costoUnitario,
      Value<int> descuento,
      Value<int> tasaIva,
      Value<int> baseGravable,
      Value<int> impuesto,
      Value<int> total,
      Value<int> rowid,
    });
typedef $$VentaDetallesTableUpdateCompanionBuilder =
    VentaDetallesCompanion Function({
      Value<String> uuid,
      Value<String> ventaUuid,
      Value<String?> productoUuid,
      Value<int> linea,
      Value<String> descripcion,
      Value<String?> skuSnapshot,
      Value<int> cantidad,
      Value<int> precioUnitario,
      Value<int> costoUnitario,
      Value<int> descuento,
      Value<int> tasaIva,
      Value<int> baseGravable,
      Value<int> impuesto,
      Value<int> total,
      Value<int> rowid,
    });

class $$VentaDetallesTableFilterComposer
    extends Composer<_$AppDatabase, $VentaDetallesTable> {
  $$VentaDetallesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ventaUuid => $composableBuilder(
    column: $table.ventaUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productoUuid => $composableBuilder(
    column: $table.productoUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get linea => $composableBuilder(
    column: $table.linea,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get skuSnapshot => $composableBuilder(
    column: $table.skuSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cantidad => $composableBuilder(
    column: $table.cantidad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get precioUnitario => $composableBuilder(
    column: $table.precioUnitario,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get costoUnitario => $composableBuilder(
    column: $table.costoUnitario,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get descuento => $composableBuilder(
    column: $table.descuento,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tasaIva => $composableBuilder(
    column: $table.tasaIva,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get baseGravable => $composableBuilder(
    column: $table.baseGravable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get impuesto => $composableBuilder(
    column: $table.impuesto,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnFilters(column),
  );
}

class $$VentaDetallesTableOrderingComposer
    extends Composer<_$AppDatabase, $VentaDetallesTable> {
  $$VentaDetallesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ventaUuid => $composableBuilder(
    column: $table.ventaUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productoUuid => $composableBuilder(
    column: $table.productoUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get linea => $composableBuilder(
    column: $table.linea,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get skuSnapshot => $composableBuilder(
    column: $table.skuSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cantidad => $composableBuilder(
    column: $table.cantidad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get precioUnitario => $composableBuilder(
    column: $table.precioUnitario,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get costoUnitario => $composableBuilder(
    column: $table.costoUnitario,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get descuento => $composableBuilder(
    column: $table.descuento,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tasaIva => $composableBuilder(
    column: $table.tasaIva,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get baseGravable => $composableBuilder(
    column: $table.baseGravable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get impuesto => $composableBuilder(
    column: $table.impuesto,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get total => $composableBuilder(
    column: $table.total,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$VentaDetallesTableAnnotationComposer
    extends Composer<_$AppDatabase, $VentaDetallesTable> {
  $$VentaDetallesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get ventaUuid =>
      $composableBuilder(column: $table.ventaUuid, builder: (column) => column);

  GeneratedColumn<String> get productoUuid => $composableBuilder(
    column: $table.productoUuid,
    builder: (column) => column,
  );

  GeneratedColumn<int> get linea =>
      $composableBuilder(column: $table.linea, builder: (column) => column);

  GeneratedColumn<String> get descripcion => $composableBuilder(
    column: $table.descripcion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get skuSnapshot => $composableBuilder(
    column: $table.skuSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cantidad =>
      $composableBuilder(column: $table.cantidad, builder: (column) => column);

  GeneratedColumn<int> get precioUnitario => $composableBuilder(
    column: $table.precioUnitario,
    builder: (column) => column,
  );

  GeneratedColumn<int> get costoUnitario => $composableBuilder(
    column: $table.costoUnitario,
    builder: (column) => column,
  );

  GeneratedColumn<int> get descuento =>
      $composableBuilder(column: $table.descuento, builder: (column) => column);

  GeneratedColumn<int> get tasaIva =>
      $composableBuilder(column: $table.tasaIva, builder: (column) => column);

  GeneratedColumn<int> get baseGravable => $composableBuilder(
    column: $table.baseGravable,
    builder: (column) => column,
  );

  GeneratedColumn<int> get impuesto =>
      $composableBuilder(column: $table.impuesto, builder: (column) => column);

  GeneratedColumn<int> get total =>
      $composableBuilder(column: $table.total, builder: (column) => column);
}

class $$VentaDetallesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $VentaDetallesTable,
          VentaDetalle,
          $$VentaDetallesTableFilterComposer,
          $$VentaDetallesTableOrderingComposer,
          $$VentaDetallesTableAnnotationComposer,
          $$VentaDetallesTableCreateCompanionBuilder,
          $$VentaDetallesTableUpdateCompanionBuilder,
          (
            VentaDetalle,
            BaseReferences<_$AppDatabase, $VentaDetallesTable, VentaDetalle>,
          ),
          VentaDetalle,
          PrefetchHooks Function()
        > {
  $$VentaDetallesTableTableManager(_$AppDatabase db, $VentaDetallesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$VentaDetallesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$VentaDetallesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$VentaDetallesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<String> ventaUuid = const Value.absent(),
                Value<String?> productoUuid = const Value.absent(),
                Value<int> linea = const Value.absent(),
                Value<String> descripcion = const Value.absent(),
                Value<String?> skuSnapshot = const Value.absent(),
                Value<int> cantidad = const Value.absent(),
                Value<int> precioUnitario = const Value.absent(),
                Value<int> costoUnitario = const Value.absent(),
                Value<int> descuento = const Value.absent(),
                Value<int> tasaIva = const Value.absent(),
                Value<int> baseGravable = const Value.absent(),
                Value<int> impuesto = const Value.absent(),
                Value<int> total = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VentaDetallesCompanion(
                uuid: uuid,
                ventaUuid: ventaUuid,
                productoUuid: productoUuid,
                linea: linea,
                descripcion: descripcion,
                skuSnapshot: skuSnapshot,
                cantidad: cantidad,
                precioUnitario: precioUnitario,
                costoUnitario: costoUnitario,
                descuento: descuento,
                tasaIva: tasaIva,
                baseGravable: baseGravable,
                impuesto: impuesto,
                total: total,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uuid,
                required String ventaUuid,
                Value<String?> productoUuid = const Value.absent(),
                Value<int> linea = const Value.absent(),
                required String descripcion,
                Value<String?> skuSnapshot = const Value.absent(),
                required int cantidad,
                required int precioUnitario,
                Value<int> costoUnitario = const Value.absent(),
                Value<int> descuento = const Value.absent(),
                Value<int> tasaIva = const Value.absent(),
                Value<int> baseGravable = const Value.absent(),
                Value<int> impuesto = const Value.absent(),
                Value<int> total = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => VentaDetallesCompanion.insert(
                uuid: uuid,
                ventaUuid: ventaUuid,
                productoUuid: productoUuid,
                linea: linea,
                descripcion: descripcion,
                skuSnapshot: skuSnapshot,
                cantidad: cantidad,
                precioUnitario: precioUnitario,
                costoUnitario: costoUnitario,
                descuento: descuento,
                tasaIva: tasaIva,
                baseGravable: baseGravable,
                impuesto: impuesto,
                total: total,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$VentaDetallesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $VentaDetallesTable,
      VentaDetalle,
      $$VentaDetallesTableFilterComposer,
      $$VentaDetallesTableOrderingComposer,
      $$VentaDetallesTableAnnotationComposer,
      $$VentaDetallesTableCreateCompanionBuilder,
      $$VentaDetallesTableUpdateCompanionBuilder,
      (
        VentaDetalle,
        BaseReferences<_$AppDatabase, $VentaDetallesTable, VentaDetalle>,
      ),
      VentaDetalle,
      PrefetchHooks Function()
    >;
typedef $$MovimientosTableCreateCompanionBuilder =
    MovimientosCompanion Function({
      required String uuid,
      required String productoUuid,
      required String tipo,
      required int cantidad,
      Value<int?> costoUnitario,
      Value<int?> precioUnitario,
      Value<int?> stockAnterior,
      Value<int?> stockResultante,
      Value<String?> ventaUuid,
      Value<String?> proveedorUuid,
      Value<String?> usuarioUuid,
      Value<String?> lote,
      Value<String?> venceEl,
      Value<String?> documentoRef,
      Value<String?> motivo,
      required DateTime fecha,
      required String fechaLocal,
      Value<bool> creadoOffline,
      Value<DateTime?> sincronizadoEn,
      Value<int> rowid,
    });
typedef $$MovimientosTableUpdateCompanionBuilder =
    MovimientosCompanion Function({
      Value<String> uuid,
      Value<String> productoUuid,
      Value<String> tipo,
      Value<int> cantidad,
      Value<int?> costoUnitario,
      Value<int?> precioUnitario,
      Value<int?> stockAnterior,
      Value<int?> stockResultante,
      Value<String?> ventaUuid,
      Value<String?> proveedorUuid,
      Value<String?> usuarioUuid,
      Value<String?> lote,
      Value<String?> venceEl,
      Value<String?> documentoRef,
      Value<String?> motivo,
      Value<DateTime> fecha,
      Value<String> fechaLocal,
      Value<bool> creadoOffline,
      Value<DateTime?> sincronizadoEn,
      Value<int> rowid,
    });

class $$MovimientosTableFilterComposer
    extends Composer<_$AppDatabase, $MovimientosTable> {
  $$MovimientosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productoUuid => $composableBuilder(
    column: $table.productoUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cantidad => $composableBuilder(
    column: $table.cantidad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get costoUnitario => $composableBuilder(
    column: $table.costoUnitario,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get precioUnitario => $composableBuilder(
    column: $table.precioUnitario,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stockAnterior => $composableBuilder(
    column: $table.stockAnterior,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stockResultante => $composableBuilder(
    column: $table.stockResultante,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ventaUuid => $composableBuilder(
    column: $table.ventaUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get proveedorUuid => $composableBuilder(
    column: $table.proveedorUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get usuarioUuid => $composableBuilder(
    column: $table.usuarioUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lote => $composableBuilder(
    column: $table.lote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get venceEl => $composableBuilder(
    column: $table.venceEl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentoRef => $composableBuilder(
    column: $table.documentoRef,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get motivo => $composableBuilder(
    column: $table.motivo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fechaLocal => $composableBuilder(
    column: $table.fechaLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get creadoOffline => $composableBuilder(
    column: $table.creadoOffline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sincronizadoEn => $composableBuilder(
    column: $table.sincronizadoEn,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MovimientosTableOrderingComposer
    extends Composer<_$AppDatabase, $MovimientosTable> {
  $$MovimientosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productoUuid => $composableBuilder(
    column: $table.productoUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cantidad => $composableBuilder(
    column: $table.cantidad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get costoUnitario => $composableBuilder(
    column: $table.costoUnitario,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get precioUnitario => $composableBuilder(
    column: $table.precioUnitario,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stockAnterior => $composableBuilder(
    column: $table.stockAnterior,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stockResultante => $composableBuilder(
    column: $table.stockResultante,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ventaUuid => $composableBuilder(
    column: $table.ventaUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get proveedorUuid => $composableBuilder(
    column: $table.proveedorUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get usuarioUuid => $composableBuilder(
    column: $table.usuarioUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lote => $composableBuilder(
    column: $table.lote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get venceEl => $composableBuilder(
    column: $table.venceEl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentoRef => $composableBuilder(
    column: $table.documentoRef,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get motivo => $composableBuilder(
    column: $table.motivo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fecha => $composableBuilder(
    column: $table.fecha,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fechaLocal => $composableBuilder(
    column: $table.fechaLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get creadoOffline => $composableBuilder(
    column: $table.creadoOffline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sincronizadoEn => $composableBuilder(
    column: $table.sincronizadoEn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MovimientosTableAnnotationComposer
    extends Composer<_$AppDatabase, $MovimientosTable> {
  $$MovimientosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get productoUuid => $composableBuilder(
    column: $table.productoUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<int> get cantidad =>
      $composableBuilder(column: $table.cantidad, builder: (column) => column);

  GeneratedColumn<int> get costoUnitario => $composableBuilder(
    column: $table.costoUnitario,
    builder: (column) => column,
  );

  GeneratedColumn<int> get precioUnitario => $composableBuilder(
    column: $table.precioUnitario,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stockAnterior => $composableBuilder(
    column: $table.stockAnterior,
    builder: (column) => column,
  );

  GeneratedColumn<int> get stockResultante => $composableBuilder(
    column: $table.stockResultante,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ventaUuid =>
      $composableBuilder(column: $table.ventaUuid, builder: (column) => column);

  GeneratedColumn<String> get proveedorUuid => $composableBuilder(
    column: $table.proveedorUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get usuarioUuid => $composableBuilder(
    column: $table.usuarioUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lote =>
      $composableBuilder(column: $table.lote, builder: (column) => column);

  GeneratedColumn<String> get venceEl =>
      $composableBuilder(column: $table.venceEl, builder: (column) => column);

  GeneratedColumn<String> get documentoRef => $composableBuilder(
    column: $table.documentoRef,
    builder: (column) => column,
  );

  GeneratedColumn<String> get motivo =>
      $composableBuilder(column: $table.motivo, builder: (column) => column);

  GeneratedColumn<DateTime> get fecha =>
      $composableBuilder(column: $table.fecha, builder: (column) => column);

  GeneratedColumn<String> get fechaLocal => $composableBuilder(
    column: $table.fechaLocal,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get creadoOffline => $composableBuilder(
    column: $table.creadoOffline,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get sincronizadoEn => $composableBuilder(
    column: $table.sincronizadoEn,
    builder: (column) => column,
  );
}

class $$MovimientosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MovimientosTable,
          Movimiento,
          $$MovimientosTableFilterComposer,
          $$MovimientosTableOrderingComposer,
          $$MovimientosTableAnnotationComposer,
          $$MovimientosTableCreateCompanionBuilder,
          $$MovimientosTableUpdateCompanionBuilder,
          (
            Movimiento,
            BaseReferences<_$AppDatabase, $MovimientosTable, Movimiento>,
          ),
          Movimiento,
          PrefetchHooks Function()
        > {
  $$MovimientosTableTableManager(_$AppDatabase db, $MovimientosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MovimientosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MovimientosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MovimientosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<String> productoUuid = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<int> cantidad = const Value.absent(),
                Value<int?> costoUnitario = const Value.absent(),
                Value<int?> precioUnitario = const Value.absent(),
                Value<int?> stockAnterior = const Value.absent(),
                Value<int?> stockResultante = const Value.absent(),
                Value<String?> ventaUuid = const Value.absent(),
                Value<String?> proveedorUuid = const Value.absent(),
                Value<String?> usuarioUuid = const Value.absent(),
                Value<String?> lote = const Value.absent(),
                Value<String?> venceEl = const Value.absent(),
                Value<String?> documentoRef = const Value.absent(),
                Value<String?> motivo = const Value.absent(),
                Value<DateTime> fecha = const Value.absent(),
                Value<String> fechaLocal = const Value.absent(),
                Value<bool> creadoOffline = const Value.absent(),
                Value<DateTime?> sincronizadoEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MovimientosCompanion(
                uuid: uuid,
                productoUuid: productoUuid,
                tipo: tipo,
                cantidad: cantidad,
                costoUnitario: costoUnitario,
                precioUnitario: precioUnitario,
                stockAnterior: stockAnterior,
                stockResultante: stockResultante,
                ventaUuid: ventaUuid,
                proveedorUuid: proveedorUuid,
                usuarioUuid: usuarioUuid,
                lote: lote,
                venceEl: venceEl,
                documentoRef: documentoRef,
                motivo: motivo,
                fecha: fecha,
                fechaLocal: fechaLocal,
                creadoOffline: creadoOffline,
                sincronizadoEn: sincronizadoEn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uuid,
                required String productoUuid,
                required String tipo,
                required int cantidad,
                Value<int?> costoUnitario = const Value.absent(),
                Value<int?> precioUnitario = const Value.absent(),
                Value<int?> stockAnterior = const Value.absent(),
                Value<int?> stockResultante = const Value.absent(),
                Value<String?> ventaUuid = const Value.absent(),
                Value<String?> proveedorUuid = const Value.absent(),
                Value<String?> usuarioUuid = const Value.absent(),
                Value<String?> lote = const Value.absent(),
                Value<String?> venceEl = const Value.absent(),
                Value<String?> documentoRef = const Value.absent(),
                Value<String?> motivo = const Value.absent(),
                required DateTime fecha,
                required String fechaLocal,
                Value<bool> creadoOffline = const Value.absent(),
                Value<DateTime?> sincronizadoEn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MovimientosCompanion.insert(
                uuid: uuid,
                productoUuid: productoUuid,
                tipo: tipo,
                cantidad: cantidad,
                costoUnitario: costoUnitario,
                precioUnitario: precioUnitario,
                stockAnterior: stockAnterior,
                stockResultante: stockResultante,
                ventaUuid: ventaUuid,
                proveedorUuid: proveedorUuid,
                usuarioUuid: usuarioUuid,
                lote: lote,
                venceEl: venceEl,
                documentoRef: documentoRef,
                motivo: motivo,
                fecha: fecha,
                fechaLocal: fechaLocal,
                creadoOffline: creadoOffline,
                sincronizadoEn: sincronizadoEn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MovimientosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MovimientosTable,
      Movimiento,
      $$MovimientosTableFilterComposer,
      $$MovimientosTableOrderingComposer,
      $$MovimientosTableAnnotationComposer,
      $$MovimientosTableCreateCompanionBuilder,
      $$MovimientosTableUpdateCompanionBuilder,
      (
        Movimiento,
        BaseReferences<_$AppDatabase, $MovimientosTable, Movimiento>,
      ),
      Movimiento,
      PrefetchHooks Function()
    >;
typedef $$AlertasTableCreateCompanionBuilder =
    AlertasCompanion Function({
      required String uuid,
      required String tipo,
      Value<String> severidad,
      Value<String?> productoUuid,
      Value<String?> ventaUuid,
      required String mensaje,
      Value<DateTime?> resueltaEn,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$AlertasTableUpdateCompanionBuilder =
    AlertasCompanion Function({
      Value<String> uuid,
      Value<String> tipo,
      Value<String> severidad,
      Value<String?> productoUuid,
      Value<String?> ventaUuid,
      Value<String> mensaje,
      Value<DateTime?> resueltaEn,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AlertasTableFilterComposer
    extends Composer<_$AppDatabase, $AlertasTable> {
  $$AlertasTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get severidad => $composableBuilder(
    column: $table.severidad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productoUuid => $composableBuilder(
    column: $table.productoUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ventaUuid => $composableBuilder(
    column: $table.ventaUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mensaje => $composableBuilder(
    column: $table.mensaje,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get resueltaEn => $composableBuilder(
    column: $table.resueltaEn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AlertasTableOrderingComposer
    extends Composer<_$AppDatabase, $AlertasTable> {
  $$AlertasTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get severidad => $composableBuilder(
    column: $table.severidad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productoUuid => $composableBuilder(
    column: $table.productoUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ventaUuid => $composableBuilder(
    column: $table.ventaUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mensaje => $composableBuilder(
    column: $table.mensaje,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get resueltaEn => $composableBuilder(
    column: $table.resueltaEn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AlertasTableAnnotationComposer
    extends Composer<_$AppDatabase, $AlertasTable> {
  $$AlertasTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<String> get severidad =>
      $composableBuilder(column: $table.severidad, builder: (column) => column);

  GeneratedColumn<String> get productoUuid => $composableBuilder(
    column: $table.productoUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ventaUuid =>
      $composableBuilder(column: $table.ventaUuid, builder: (column) => column);

  GeneratedColumn<String> get mensaje =>
      $composableBuilder(column: $table.mensaje, builder: (column) => column);

  GeneratedColumn<DateTime> get resueltaEn => $composableBuilder(
    column: $table.resueltaEn,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AlertasTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AlertasTable,
          Alerta,
          $$AlertasTableFilterComposer,
          $$AlertasTableOrderingComposer,
          $$AlertasTableAnnotationComposer,
          $$AlertasTableCreateCompanionBuilder,
          $$AlertasTableUpdateCompanionBuilder,
          (Alerta, BaseReferences<_$AppDatabase, $AlertasTable, Alerta>),
          Alerta,
          PrefetchHooks Function()
        > {
  $$AlertasTableTableManager(_$AppDatabase db, $AlertasTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AlertasTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AlertasTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AlertasTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uuid = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<String> severidad = const Value.absent(),
                Value<String?> productoUuid = const Value.absent(),
                Value<String?> ventaUuid = const Value.absent(),
                Value<String> mensaje = const Value.absent(),
                Value<DateTime?> resueltaEn = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlertasCompanion(
                uuid: uuid,
                tipo: tipo,
                severidad: severidad,
                productoUuid: productoUuid,
                ventaUuid: ventaUuid,
                mensaje: mensaje,
                resueltaEn: resueltaEn,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uuid,
                required String tipo,
                Value<String> severidad = const Value.absent(),
                Value<String?> productoUuid = const Value.absent(),
                Value<String?> ventaUuid = const Value.absent(),
                required String mensaje,
                Value<DateTime?> resueltaEn = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AlertasCompanion.insert(
                uuid: uuid,
                tipo: tipo,
                severidad: severidad,
                productoUuid: productoUuid,
                ventaUuid: ventaUuid,
                mensaje: mensaje,
                resueltaEn: resueltaEn,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AlertasTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AlertasTable,
      Alerta,
      $$AlertasTableFilterComposer,
      $$AlertasTableOrderingComposer,
      $$AlertasTableAnnotationComposer,
      $$AlertasTableCreateCompanionBuilder,
      $$AlertasTableUpdateCompanionBuilder,
      (Alerta, BaseReferences<_$AppDatabase, $AlertasTable, Alerta>),
      Alerta,
      PrefetchHooks Function()
    >;
typedef $$SyncOutboxTableCreateCompanionBuilder =
    SyncOutboxCompanion Function({
      Value<int> id,
      required String clientOpId,
      required String tipo,
      required String entidad,
      Value<String?> entidadUuid,
      required String payload,
      Value<int> intentos,
      Value<String?> ultimoError,
      Value<String?> codigoError,
      Value<String> estado,
      Value<DateTime> proximoIntento,
      Value<DateTime> creadoEn,
    });
typedef $$SyncOutboxTableUpdateCompanionBuilder =
    SyncOutboxCompanion Function({
      Value<int> id,
      Value<String> clientOpId,
      Value<String> tipo,
      Value<String> entidad,
      Value<String?> entidadUuid,
      Value<String> payload,
      Value<int> intentos,
      Value<String?> ultimoError,
      Value<String?> codigoError,
      Value<String> estado,
      Value<DateTime> proximoIntento,
      Value<DateTime> creadoEn,
    });

class $$SyncOutboxTableFilterComposer
    extends Composer<_$AppDatabase, $SyncOutboxTable> {
  $$SyncOutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientOpId => $composableBuilder(
    column: $table.clientOpId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entidad => $composableBuilder(
    column: $table.entidad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entidadUuid => $composableBuilder(
    column: $table.entidadUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intentos => $composableBuilder(
    column: $table.intentos,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ultimoError => $composableBuilder(
    column: $table.ultimoError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codigoError => $composableBuilder(
    column: $table.codigoError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get proximoIntento => $composableBuilder(
    column: $table.proximoIntento,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncOutboxTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncOutboxTable> {
  $$SyncOutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientOpId => $composableBuilder(
    column: $table.clientOpId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entidad => $composableBuilder(
    column: $table.entidad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entidadUuid => $composableBuilder(
    column: $table.entidadUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intentos => $composableBuilder(
    column: $table.intentos,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ultimoError => $composableBuilder(
    column: $table.ultimoError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codigoError => $composableBuilder(
    column: $table.codigoError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get estado => $composableBuilder(
    column: $table.estado,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get proximoIntento => $composableBuilder(
    column: $table.proximoIntento,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creadoEn => $composableBuilder(
    column: $table.creadoEn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncOutboxTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncOutboxTable> {
  $$SyncOutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientOpId => $composableBuilder(
    column: $table.clientOpId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);

  GeneratedColumn<String> get entidad =>
      $composableBuilder(column: $table.entidad, builder: (column) => column);

  GeneratedColumn<String> get entidadUuid => $composableBuilder(
    column: $table.entidadUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<int> get intentos =>
      $composableBuilder(column: $table.intentos, builder: (column) => column);

  GeneratedColumn<String> get ultimoError => $composableBuilder(
    column: $table.ultimoError,
    builder: (column) => column,
  );

  GeneratedColumn<String> get codigoError => $composableBuilder(
    column: $table.codigoError,
    builder: (column) => column,
  );

  GeneratedColumn<String> get estado =>
      $composableBuilder(column: $table.estado, builder: (column) => column);

  GeneratedColumn<DateTime> get proximoIntento => $composableBuilder(
    column: $table.proximoIntento,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get creadoEn =>
      $composableBuilder(column: $table.creadoEn, builder: (column) => column);
}

class $$SyncOutboxTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncOutboxTable,
          SyncOutboxData,
          $$SyncOutboxTableFilterComposer,
          $$SyncOutboxTableOrderingComposer,
          $$SyncOutboxTableAnnotationComposer,
          $$SyncOutboxTableCreateCompanionBuilder,
          $$SyncOutboxTableUpdateCompanionBuilder,
          (
            SyncOutboxData,
            BaseReferences<_$AppDatabase, $SyncOutboxTable, SyncOutboxData>,
          ),
          SyncOutboxData,
          PrefetchHooks Function()
        > {
  $$SyncOutboxTableTableManager(_$AppDatabase db, $SyncOutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncOutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncOutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncOutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> clientOpId = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<String> entidad = const Value.absent(),
                Value<String?> entidadUuid = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> intentos = const Value.absent(),
                Value<String?> ultimoError = const Value.absent(),
                Value<String?> codigoError = const Value.absent(),
                Value<String> estado = const Value.absent(),
                Value<DateTime> proximoIntento = const Value.absent(),
                Value<DateTime> creadoEn = const Value.absent(),
              }) => SyncOutboxCompanion(
                id: id,
                clientOpId: clientOpId,
                tipo: tipo,
                entidad: entidad,
                entidadUuid: entidadUuid,
                payload: payload,
                intentos: intentos,
                ultimoError: ultimoError,
                codigoError: codigoError,
                estado: estado,
                proximoIntento: proximoIntento,
                creadoEn: creadoEn,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String clientOpId,
                required String tipo,
                required String entidad,
                Value<String?> entidadUuid = const Value.absent(),
                required String payload,
                Value<int> intentos = const Value.absent(),
                Value<String?> ultimoError = const Value.absent(),
                Value<String?> codigoError = const Value.absent(),
                Value<String> estado = const Value.absent(),
                Value<DateTime> proximoIntento = const Value.absent(),
                Value<DateTime> creadoEn = const Value.absent(),
              }) => SyncOutboxCompanion.insert(
                id: id,
                clientOpId: clientOpId,
                tipo: tipo,
                entidad: entidad,
                entidadUuid: entidadUuid,
                payload: payload,
                intentos: intentos,
                ultimoError: ultimoError,
                codigoError: codigoError,
                estado: estado,
                proximoIntento: proximoIntento,
                creadoEn: creadoEn,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncOutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncOutboxTable,
      SyncOutboxData,
      $$SyncOutboxTableFilterComposer,
      $$SyncOutboxTableOrderingComposer,
      $$SyncOutboxTableAnnotationComposer,
      $$SyncOutboxTableCreateCompanionBuilder,
      $$SyncOutboxTableUpdateCompanionBuilder,
      (
        SyncOutboxData,
        BaseReferences<_$AppDatabase, $SyncOutboxTable, SyncOutboxData>,
      ),
      SyncOutboxData,
      PrefetchHooks Function()
    >;
typedef $$SyncCursoresTableCreateCompanionBuilder =
    SyncCursoresCompanion Function({
      required String entidad,
      required DateTime cursorT,
      Value<int> cursorI,
      Value<DateTime?> ultimoSync,
      Value<int> rowid,
    });
typedef $$SyncCursoresTableUpdateCompanionBuilder =
    SyncCursoresCompanion Function({
      Value<String> entidad,
      Value<DateTime> cursorT,
      Value<int> cursorI,
      Value<DateTime?> ultimoSync,
      Value<int> rowid,
    });

class $$SyncCursoresTableFilterComposer
    extends Composer<_$AppDatabase, $SyncCursoresTable> {
  $$SyncCursoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entidad => $composableBuilder(
    column: $table.entidad,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get cursorT => $composableBuilder(
    column: $table.cursorT,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cursorI => $composableBuilder(
    column: $table.cursorI,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get ultimoSync => $composableBuilder(
    column: $table.ultimoSync,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncCursoresTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncCursoresTable> {
  $$SyncCursoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entidad => $composableBuilder(
    column: $table.entidad,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get cursorT => $composableBuilder(
    column: $table.cursorT,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cursorI => $composableBuilder(
    column: $table.cursorI,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get ultimoSync => $composableBuilder(
    column: $table.ultimoSync,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncCursoresTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncCursoresTable> {
  $$SyncCursoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entidad =>
      $composableBuilder(column: $table.entidad, builder: (column) => column);

  GeneratedColumn<DateTime> get cursorT =>
      $composableBuilder(column: $table.cursorT, builder: (column) => column);

  GeneratedColumn<int> get cursorI =>
      $composableBuilder(column: $table.cursorI, builder: (column) => column);

  GeneratedColumn<DateTime> get ultimoSync => $composableBuilder(
    column: $table.ultimoSync,
    builder: (column) => column,
  );
}

class $$SyncCursoresTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncCursoresTable,
          SyncCursor,
          $$SyncCursoresTableFilterComposer,
          $$SyncCursoresTableOrderingComposer,
          $$SyncCursoresTableAnnotationComposer,
          $$SyncCursoresTableCreateCompanionBuilder,
          $$SyncCursoresTableUpdateCompanionBuilder,
          (
            SyncCursor,
            BaseReferences<_$AppDatabase, $SyncCursoresTable, SyncCursor>,
          ),
          SyncCursor,
          PrefetchHooks Function()
        > {
  $$SyncCursoresTableTableManager(_$AppDatabase db, $SyncCursoresTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncCursoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncCursoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncCursoresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entidad = const Value.absent(),
                Value<DateTime> cursorT = const Value.absent(),
                Value<int> cursorI = const Value.absent(),
                Value<DateTime?> ultimoSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncCursoresCompanion(
                entidad: entidad,
                cursorT: cursorT,
                cursorI: cursorI,
                ultimoSync: ultimoSync,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entidad,
                required DateTime cursorT,
                Value<int> cursorI = const Value.absent(),
                Value<DateTime?> ultimoSync = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncCursoresCompanion.insert(
                entidad: entidad,
                cursorT: cursorT,
                cursorI: cursorI,
                ultimoSync: ultimoSync,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncCursoresTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncCursoresTable,
      SyncCursor,
      $$SyncCursoresTableFilterComposer,
      $$SyncCursoresTableOrderingComposer,
      $$SyncCursoresTableAnnotationComposer,
      $$SyncCursoresTableCreateCompanionBuilder,
      $$SyncCursoresTableUpdateCompanionBuilder,
      (
        SyncCursor,
        BaseReferences<_$AppDatabase, $SyncCursoresTable, SyncCursor>,
      ),
      SyncCursor,
      PrefetchHooks Function()
    >;
typedef $$ConfiguracionTableCreateCompanionBuilder =
    ConfiguracionCompanion Function({
      required String clave,
      required String valor,
      Value<String> tipo,
      Value<int> rowid,
    });
typedef $$ConfiguracionTableUpdateCompanionBuilder =
    ConfiguracionCompanion Function({
      Value<String> clave,
      Value<String> valor,
      Value<String> tipo,
      Value<int> rowid,
    });

class $$ConfiguracionTableFilterComposer
    extends Composer<_$AppDatabase, $ConfiguracionTable> {
  $$ConfiguracionTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get clave => $composableBuilder(
    column: $table.clave,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valor => $composableBuilder(
    column: $table.valor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConfiguracionTableOrderingComposer
    extends Composer<_$AppDatabase, $ConfiguracionTable> {
  $$ConfiguracionTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get clave => $composableBuilder(
    column: $table.clave,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valor => $composableBuilder(
    column: $table.valor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tipo => $composableBuilder(
    column: $table.tipo,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConfiguracionTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConfiguracionTable> {
  $$ConfiguracionTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get clave =>
      $composableBuilder(column: $table.clave, builder: (column) => column);

  GeneratedColumn<String> get valor =>
      $composableBuilder(column: $table.valor, builder: (column) => column);

  GeneratedColumn<String> get tipo =>
      $composableBuilder(column: $table.tipo, builder: (column) => column);
}

class $$ConfiguracionTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConfiguracionTable,
          ConfiguracionData,
          $$ConfiguracionTableFilterComposer,
          $$ConfiguracionTableOrderingComposer,
          $$ConfiguracionTableAnnotationComposer,
          $$ConfiguracionTableCreateCompanionBuilder,
          $$ConfiguracionTableUpdateCompanionBuilder,
          (
            ConfiguracionData,
            BaseReferences<
              _$AppDatabase,
              $ConfiguracionTable,
              ConfiguracionData
            >,
          ),
          ConfiguracionData,
          PrefetchHooks Function()
        > {
  $$ConfiguracionTableTableManager(_$AppDatabase db, $ConfiguracionTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConfiguracionTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConfiguracionTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConfiguracionTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> clave = const Value.absent(),
                Value<String> valor = const Value.absent(),
                Value<String> tipo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConfiguracionCompanion(
                clave: clave,
                valor: valor,
                tipo: tipo,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String clave,
                required String valor,
                Value<String> tipo = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConfiguracionCompanion.insert(
                clave: clave,
                valor: valor,
                tipo: tipo,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConfiguracionTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConfiguracionTable,
      ConfiguracionData,
      $$ConfiguracionTableFilterComposer,
      $$ConfiguracionTableOrderingComposer,
      $$ConfiguracionTableAnnotationComposer,
      $$ConfiguracionTableCreateCompanionBuilder,
      $$ConfiguracionTableUpdateCompanionBuilder,
      (
        ConfiguracionData,
        BaseReferences<_$AppDatabase, $ConfiguracionTable, ConfiguracionData>,
      ),
      ConfiguracionData,
      PrefetchHooks Function()
    >;
typedef $$EstadoAppTableCreateCompanionBuilder =
    EstadoAppCompanion Function({
      Value<int> id,
      Value<String?> usuarioUuid,
      Value<String?> dispositivoUuid,
      Value<String?> prefijoFolio,
      Value<int> secuenciaFolio,
      Value<DateTime?> offlineValidoHasta,
      Value<DateTime?> ultimoSyncExitoso,
    });
typedef $$EstadoAppTableUpdateCompanionBuilder =
    EstadoAppCompanion Function({
      Value<int> id,
      Value<String?> usuarioUuid,
      Value<String?> dispositivoUuid,
      Value<String?> prefijoFolio,
      Value<int> secuenciaFolio,
      Value<DateTime?> offlineValidoHasta,
      Value<DateTime?> ultimoSyncExitoso,
    });

class $$EstadoAppTableFilterComposer
    extends Composer<_$AppDatabase, $EstadoAppTable> {
  $$EstadoAppTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get usuarioUuid => $composableBuilder(
    column: $table.usuarioUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dispositivoUuid => $composableBuilder(
    column: $table.dispositivoUuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prefijoFolio => $composableBuilder(
    column: $table.prefijoFolio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get secuenciaFolio => $composableBuilder(
    column: $table.secuenciaFolio,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get offlineValidoHasta => $composableBuilder(
    column: $table.offlineValidoHasta,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get ultimoSyncExitoso => $composableBuilder(
    column: $table.ultimoSyncExitoso,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EstadoAppTableOrderingComposer
    extends Composer<_$AppDatabase, $EstadoAppTable> {
  $$EstadoAppTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get usuarioUuid => $composableBuilder(
    column: $table.usuarioUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dispositivoUuid => $composableBuilder(
    column: $table.dispositivoUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prefijoFolio => $composableBuilder(
    column: $table.prefijoFolio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get secuenciaFolio => $composableBuilder(
    column: $table.secuenciaFolio,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get offlineValidoHasta => $composableBuilder(
    column: $table.offlineValidoHasta,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get ultimoSyncExitoso => $composableBuilder(
    column: $table.ultimoSyncExitoso,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EstadoAppTableAnnotationComposer
    extends Composer<_$AppDatabase, $EstadoAppTable> {
  $$EstadoAppTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get usuarioUuid => $composableBuilder(
    column: $table.usuarioUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dispositivoUuid => $composableBuilder(
    column: $table.dispositivoUuid,
    builder: (column) => column,
  );

  GeneratedColumn<String> get prefijoFolio => $composableBuilder(
    column: $table.prefijoFolio,
    builder: (column) => column,
  );

  GeneratedColumn<int> get secuenciaFolio => $composableBuilder(
    column: $table.secuenciaFolio,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get offlineValidoHasta => $composableBuilder(
    column: $table.offlineValidoHasta,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get ultimoSyncExitoso => $composableBuilder(
    column: $table.ultimoSyncExitoso,
    builder: (column) => column,
  );
}

class $$EstadoAppTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EstadoAppTable,
          EstadoAppData,
          $$EstadoAppTableFilterComposer,
          $$EstadoAppTableOrderingComposer,
          $$EstadoAppTableAnnotationComposer,
          $$EstadoAppTableCreateCompanionBuilder,
          $$EstadoAppTableUpdateCompanionBuilder,
          (
            EstadoAppData,
            BaseReferences<_$AppDatabase, $EstadoAppTable, EstadoAppData>,
          ),
          EstadoAppData,
          PrefetchHooks Function()
        > {
  $$EstadoAppTableTableManager(_$AppDatabase db, $EstadoAppTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EstadoAppTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EstadoAppTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EstadoAppTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> usuarioUuid = const Value.absent(),
                Value<String?> dispositivoUuid = const Value.absent(),
                Value<String?> prefijoFolio = const Value.absent(),
                Value<int> secuenciaFolio = const Value.absent(),
                Value<DateTime?> offlineValidoHasta = const Value.absent(),
                Value<DateTime?> ultimoSyncExitoso = const Value.absent(),
              }) => EstadoAppCompanion(
                id: id,
                usuarioUuid: usuarioUuid,
                dispositivoUuid: dispositivoUuid,
                prefijoFolio: prefijoFolio,
                secuenciaFolio: secuenciaFolio,
                offlineValidoHasta: offlineValidoHasta,
                ultimoSyncExitoso: ultimoSyncExitoso,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> usuarioUuid = const Value.absent(),
                Value<String?> dispositivoUuid = const Value.absent(),
                Value<String?> prefijoFolio = const Value.absent(),
                Value<int> secuenciaFolio = const Value.absent(),
                Value<DateTime?> offlineValidoHasta = const Value.absent(),
                Value<DateTime?> ultimoSyncExitoso = const Value.absent(),
              }) => EstadoAppCompanion.insert(
                id: id,
                usuarioUuid: usuarioUuid,
                dispositivoUuid: dispositivoUuid,
                prefijoFolio: prefijoFolio,
                secuenciaFolio: secuenciaFolio,
                offlineValidoHasta: offlineValidoHasta,
                ultimoSyncExitoso: ultimoSyncExitoso,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EstadoAppTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EstadoAppTable,
      EstadoAppData,
      $$EstadoAppTableFilterComposer,
      $$EstadoAppTableOrderingComposer,
      $$EstadoAppTableAnnotationComposer,
      $$EstadoAppTableCreateCompanionBuilder,
      $$EstadoAppTableUpdateCompanionBuilder,
      (
        EstadoAppData,
        BaseReferences<_$AppDatabase, $EstadoAppTable, EstadoAppData>,
      ),
      EstadoAppData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$UsuariosTableTableManager get usuarios =>
      $$UsuariosTableTableManager(_db, _db.usuarios);
  $$CategoriasTableTableManager get categorias =>
      $$CategoriasTableTableManager(_db, _db.categorias);
  $$ProveedoresTableTableManager get proveedores =>
      $$ProveedoresTableTableManager(_db, _db.proveedores);
  $$ProductosTableTableManager get productos =>
      $$ProductosTableTableManager(_db, _db.productos);
  $$ProductoCodigosTableTableManager get productoCodigos =>
      $$ProductoCodigosTableTableManager(_db, _db.productoCodigos);
  $$VentasTableTableManager get ventas =>
      $$VentasTableTableManager(_db, _db.ventas);
  $$VentaDetallesTableTableManager get ventaDetalles =>
      $$VentaDetallesTableTableManager(_db, _db.ventaDetalles);
  $$MovimientosTableTableManager get movimientos =>
      $$MovimientosTableTableManager(_db, _db.movimientos);
  $$AlertasTableTableManager get alertas =>
      $$AlertasTableTableManager(_db, _db.alertas);
  $$SyncOutboxTableTableManager get syncOutbox =>
      $$SyncOutboxTableTableManager(_db, _db.syncOutbox);
  $$SyncCursoresTableTableManager get syncCursores =>
      $$SyncCursoresTableTableManager(_db, _db.syncCursores);
  $$ConfiguracionTableTableManager get configuracion =>
      $$ConfiguracionTableTableManager(_db, _db.configuracion);
  $$EstadoAppTableTableManager get estadoApp =>
      $$EstadoAppTableTableManager(_db, _db.estadoApp);
}
