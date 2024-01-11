class QrResultModel {
  String base_percentage;
  bool counterfeit;
  String match;
  bool success;
  String url;

  QrResultModel(
      {this.base_percentage="0",
      this.counterfeit=false,
      this.match="0",
      this.success=false,
      this.url="0"});

  factory QrResultModel.fromJson(Map<String, dynamic> json) {
    return QrResultModel(
      base_percentage: json['base_percentage'],
      counterfeit: json['counterfeit'],
      match: json['match'],
      success: json['success'],
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['base_percentage'] = this.base_percentage;
    data['counterfeit'] = this.counterfeit;
    data['match'] = this.match;
    data['success'] = this.success;
    data['url'] = this.url;
    return data;
  }
}
