class ReportEntity {
  final String id;
  final String companyId;
  final String title;
  final String
      type; // financial_revenue, financial_expense, financial_profit_loss, financial_cash_flow, financial_outstanding_receivables, financial_customer_ledger, financial_driver_expense, financial_vehicle_expense, fleet_vehicle_utilization, fleet_trip_summary, fleet_availability, fleet_driver_utilization, fleet_driver_performance, fleet_fuel_consumption, fleet_maintenance_cost, fleet_inventory_usage, customer_revenue, customer_outstanding, customer_payment_history, customer_contract_summary
  final Map<String, dynamic> filters;
  final Map<String, dynamic> data; // Contains summary KPIs and rows
  final DateTime generatedAt;
  final String generatedBy;

  const ReportEntity({
    required this.id,
    required this.companyId,
    required this.title,
    required this.type,
    required this.filters,
    required this.data,
    required this.generatedAt,
    required this.generatedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyId': companyId,
      'type': type,
      'filters': filters,
      'data': data,
      'generatedAt': generatedAt.toIso8601String(),
      'generatedBy': generatedBy,
    };
  }

  factory ReportEntity.fromMap(Map<String, dynamic> map) {
    return ReportEntity(
      id: map['id'] as String? ?? '',
      companyId: map['companyId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      type: map['type'] as String? ?? '',
      filters: Map<String, dynamic>.from((map['filters'] as Map?) ?? {}),
      data: Map<String, dynamic>.from((map['data'] as Map?) ?? {}),
      generatedAt: map['generatedAt'] != null
          ? DateTime.parse(map['generatedAt'] as String)
          : DateTime.now(),
      generatedBy: map['generatedBy'] as String? ?? '',
    );
  }

  ReportEntity copyWith({
    String? id,
    String? companyId,
    String? title,
    String? type,
    Map<String, dynamic>? filters,
    Map<String, dynamic>? data,
    DateTime? generatedAt,
    String? generatedBy,
  }) {
    return ReportEntity(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      title: title ?? this.title,
      type: type ?? this.type,
      filters: filters ?? this.filters,
      data: data ?? this.data,
      generatedAt: generatedAt ?? this.generatedAt,
      generatedBy: generatedBy ?? this.generatedBy,
    );
  }
}
