class SFaceRecognitionService {
  static final SFaceRecognitionService instance = SFaceRecognitionService._();
  SFaceRecognitionService._();

  Future<void> init() async {}
  Future<void> dispose() async {}

  Future<List<double>?> extractEmbeddingFromCrop(dynamic faceImage) async =>
      null;

  Future<List<double>?> extractEmbeddingFromNv21({
    required dynamic nv21Bytes,
    required int width,
    required int height,
    required dynamic rotation,
    required dynamic face,
    bool enforceQuality = true,
  }) async => null;

  bool get isInitialized => false;
  String? get lastError => null;
}
