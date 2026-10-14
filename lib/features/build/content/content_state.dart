import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:train_with_vimal/data/mock/library_mock.dart';
import 'package:train_with_vimal/data/models/library.dart';

/// Content library items.
class ContentController extends Notifier<List<ContentItem>> {
  @override
  List<ContentItem> build() => LibraryMock.contentItems;

  void add(ContentItem c) => state = [c, ...state];
  void update(String id, ContentItem Function(ContentItem) fn) => state = [for (final c in state) c.id == id ? fn(c) : c];
  void remove(String id) => state = state.where((c) => c.id != id).toList();
  void restore(List<ContentItem> list) => state = list;
}

final contentProvider = NotifierProvider<ContentController, List<ContentItem>>(ContentController.new);

/// Content categories (the rail / chips).
class CategoriesController extends Notifier<List<String>> {
  @override
  List<String> build() => LibraryMock.contentCategories;

  void add(String c) => state = [...state, c];
}

final contentCategoriesProvider = NotifierProvider<CategoriesController, List<String>>(CategoriesController.new);

IconData kindIcon(ContentKind k) => switch (k) {
      ContentKind.video => Icons.videocam_outlined,
      ContentKind.article => Icons.article_outlined,
      ContentKind.pdf => Icons.picture_as_pdf_outlined,
      ContentKind.image => Icons.image_outlined,
    };

/// "Everyone", one client's name, "3 clients" or "Not assigned".
String whoLabel(ContentItem x) => x.everyone ? 'Everyone' : (x.clients.isEmpty ? 'Not assigned' : (x.clients.length == 1 ? x.clients.first : '${x.clients.length} clients'));

String fileName(ContentItem x) {
  var base = x.title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  if (base.endsWith('-')) base = base.substring(0, base.length - 1);
  return base +
      switch (x.kind) {
        ContentKind.video => '.mp4',
        ContentKind.article => '',
        ContentKind.pdf => '.pdf',
        ContentKind.image => '.${x.length.toLowerCase()}',
      };
}

String fileSize(ContentItem x) => switch (x.kind) {
      ContentKind.video => 'Uploaded ${x.updated} · ${8 + x.title.length % 30} MB · 1080p',
      ContentKind.pdf => '${x.length} · ${(0.4 + (x.title.length % 9) / 5).toStringAsFixed(1)} MB · uploaded ${x.updated}',
      _ => '1080 × 1350 · ${180 + x.title.length * 9} KB · uploaded ${x.updated}',
    };
