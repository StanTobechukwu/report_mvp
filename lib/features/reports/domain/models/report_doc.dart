import 'package:flutter/foundation.dart';
import 'nodes.dart';

enum ImagePlacementChoice {
  attachmentsOnly, // max 8
  inlinePage1,     // max 12 (4 inline + up to 8 attachments)
}

@immutable
class ImageAttachment {
  final String id;
  final String filePath;
  const ImageAttachment({required this.id, required this.filePath});
}

@immutable
class RecommendationBlock {
  final String text;
  const RecommendationBlock({this.text = ''});

  RecommendationBlock copyWith({String? text}) => RecommendationBlock(text: text ?? this.text);
}

@immutable
class SignatureBlock {
  final String name;
  final String credentials;
  final String? signatureFilePath;

  const SignatureBlock({
    this.name = '',
    this.credentials = '',
    this.signatureFilePath,
  });

  SignatureBlock copyWith({String? name, String? credentials, String? signatureFilePath}) {
    return SignatureBlock(
      name: name ?? this.name,
      credentials: credentials ?? this.credentials,
      signatureFilePath: signatureFilePath ?? this.signatureFilePath,
    );
  }
}

@immutable
class ReportDoc {
  final String reportId;       // storage id
  final String createdAtIso;   // storage metadata
  final String updatedAtIso;   // storage metadata

  final List<SectionNode> roots;
  final List<ImageAttachment> images;
  final ImagePlacementChoice placementChoice;

  final RecommendationBlock recommendation;
  final SignatureBlock signature;

  const ReportDoc({
    required this.reportId,
    required this.createdAtIso,
    required this.updatedAtIso,
    this.roots = const [],
    this.images = const [],
    this.placementChoice = ImagePlacementChoice.attachmentsOnly,
    this.recommendation = const RecommendationBlock(),
    this.signature = const SignatureBlock(),
  });

  int get maxImages => placementChoice == ImagePlacementChoice.inlinePage1 ? 12 : 8;

  ReportDoc copyWith({
    String? reportId,
    String? createdAtIso,
    String? updatedAtIso,
    List<SectionNode>? roots,
    List<ImageAttachment>? images,
    ImagePlacementChoice? placementChoice,
    RecommendationBlock? recommendation,
    SignatureBlock? signature,
  }) {
    return ReportDoc(
      reportId: reportId ?? this.reportId,
      createdAtIso: createdAtIso ?? this.createdAtIso,
      updatedAtIso: updatedAtIso ?? this.updatedAtIso,
      roots: roots ?? this.roots,
      images: images ?? this.images,
      placementChoice: placementChoice ?? this.placementChoice,
      recommendation: recommendation ?? this.recommendation,
      signature: signature ?? this.signature,
    );
  }
}
