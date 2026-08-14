class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final String timestamp;
  
  // Agentic fields
  final String? agentName;
  final String? intent;
  final double? confidenceScore;
  final bool? isVerified;
  final List<Map<String, dynamic>>? citations;
  final List<String>? sources;
  final String? verseReference;
  final Map<String, dynamic>? rawData;

  ChatMessage({
    this.id = '',
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.agentName,
    this.intent,
    this.confidenceScore,
    this.isVerified,
    this.citations,
    this.sources,
    this.verseReference,
    this.rawData,
  });

  factory ChatMessage.fromUser(String text) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      isUser: true,
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  factory ChatMessage.fromAgent({
    required String text,
    Map<String, dynamic>? data,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      isUser: false,
      timestamp: DateTime.now().toIso8601String(),
      agentName: data?['agent'] ?? data?['agent_name'],
      intent: data?['intent'],
      confidenceScore: data?['confidence'] ?? data?['score'],
      isVerified: data?['verified'],
      citations: data?['citations'] != null
          ? List<Map<String, dynamic>>.from(data!['citations'])
          : null,
      sources: data?['sources'] != null
          ? List<String>.from(data!['sources'])
          : null,
      verseReference: data?['verse_reference'],
      rawData: data,
    );
  }

  // ✅ FIXED: fromJson with optional isUser parameter
  factory ChatMessage.fromJson(Map<String, dynamic> json, {bool? isUser}) {
    return ChatMessage(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      isUser: isUser ?? json['isUser'] ?? false,
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
      agentName: json['agentName'],
      intent: json['intent'],
      confidenceScore: json['confidenceScore']?.toDouble(),
      isVerified: json['isVerified'],
      citations: json['citations'] != null
          ? List<Map<String, dynamic>>.from(json['citations'])
          : null,
      sources: json['sources'] != null
          ? List<String>.from(json['sources'])
          : null,
      verseReference: json['verseReference'],
      rawData: json['rawData'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp,
      'agentName': agentName,
      'intent': intent,
      'confidenceScore': confidenceScore,
      'isVerified': isVerified,
      'citations': citations,
      'sources': sources,
      'verseReference': verseReference,
      'rawData': rawData,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isUser,
    String? timestamp,
    String? agentName,
    String? intent,
    double? confidenceScore,
    bool? isVerified,
    List<Map<String, dynamic>>? citations,
    List<String>? sources,
    String? verseReference,
    Map<String, dynamic>? rawData,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      agentName: agentName ?? this.agentName,
      intent: intent ?? this.intent,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      isVerified: isVerified ?? this.isVerified,
      citations: citations ?? this.citations,
      sources: sources ?? this.sources,
      verseReference: verseReference ?? this.verseReference,
      rawData: rawData ?? this.rawData,
    );
  }
}