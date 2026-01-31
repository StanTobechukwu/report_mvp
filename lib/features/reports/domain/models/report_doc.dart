import 'package:flutter/foundation.dart';
import 'nodes.dart';
import 'subject_info_value.dart';

enum ImagePlacementChoice {
  attachmentsOnly,
  inlinePage1,
}

@immutable
class ImageAttachment {
  final String id;
  final String filePath;
  const ImageAttachment({required this.id, required this.filePath});
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

  SignatureBlock copyWith({
    String? name,
    String? credentials,
    String? signatureFilePath,
  }) {
    return SignatureBlock(
      name: name ?? this.name,
      credentials: credentials ?? this.credentials,
      signatureFilePath: signatureFilePath ?? this.signatureFilePath,
    );
  }
}

@immutable
class ReportDoc {
  final String reportId;
  final String createdAtIso;
  final String updatedAtIso;

  final List<SectionNode> roots;
  final List<ImageAttachment> images;
  final ImagePlacementChoice placementChoice;
  final SignatureBlock signature;

  /// Subject Info VALUES ONLY (exception: not part of node tree)
  final SubjectInfoValues subjectInfo;

  const ReportDoc({
    required this.reportId,
    required this.createdAtIso,
    required this.updatedAtIso,
    this.roots = const [],
    this.images = const [],
    this.placementChoice = ImagePlacementChoice.attachmentsOnly,
    this.signature = const SignatureBlock(),
    SubjectInfoValues? subjectInfo,
  }) : subjectInfo = subjectInfo ?? const SubjectInfoValues({});

  int get maxImages =>
      placementChoice == ImagePlacementChoice.inlinePage1 ? 12 : 8;

  ReportDoc copyWith({
    String? createdAtIso,
    String? updatedAtIso,
    List<SectionNode>? roots,
    List<ImageAttachment>? images,
    ImagePlacementChoice? placementChoice,
    SignatureBlock? signature,
    SubjectInfoValues? subjectInfo,
  }) {
    return ReportDoc(
      reportId: reportId,
      createdAtIso: createdAtIso ?? this.createdAtIso,
      updatedAtIso: updatedAtIso ?? this.updatedAtIso,
      roots: roots ?? this.roots,
      images: images ?? this.images,
      placementChoice: placementChoice ?? this.placementChoice,
      signature: signature ?? this.signature,
      subjectInfo: subjectInfo ?? this.subjectInfo,
    );
  }
}
