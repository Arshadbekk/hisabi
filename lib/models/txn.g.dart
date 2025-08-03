// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'txn.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TxnAdapter extends TypeAdapter<Txn> {
  @override
  final int typeId = 0;

  @override
  Txn read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Txn(
      id: fields[0] as String,
      amount: fields[1] as double,
      formattedAmount: fields[2] as String,
      currencyCode: fields[3] as String,
      currencySymbol: fields[4] as String,
      categoryId: fields[5] as String,
      categoryName: fields[6] as String,
      description: fields[7] as String,
      paymentType: fields[8] as String,
      date: fields[9] as DateTime,
      isSynced: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Txn obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.formattedAmount)
      ..writeByte(3)
      ..write(obj.currencyCode)
      ..writeByte(4)
      ..write(obj.currencySymbol)
      ..writeByte(5)
      ..write(obj.categoryId)
      ..writeByte(6)
      ..write(obj.categoryName)
      ..writeByte(7)
      ..write(obj.description)
      ..writeByte(8)
      ..write(obj.paymentType)
      ..writeByte(9)
      ..write(obj.date)
      ..writeByte(10)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TxnAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
