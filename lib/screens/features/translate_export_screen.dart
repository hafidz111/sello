import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sello/core/utils/responsive.dart';
import 'package:sello/models/product_translation_bundle.dart';
import 'package:sello/providers/auth_provider.dart';
import 'package:sello/providers/translate_export_provider.dart';
import 'package:sello/styles/app_colors.dart';
import 'package:sello/styles/app_text_styles.dart';
import 'package:sello/widgets/common/app_snackbar.dart';
import 'package:sello/widgets/features/translate_export/translate_export_actions.dart';
import 'package:sello/widgets/features/translate_export/translate_language_tabs.dart';
import 'package:sello/widgets/features/translate_export/translate_product_picker.dart';
import 'package:sello/widgets/features/translate_export/translate_result_card.dart';

class TranslateExportScreen extends StatelessWidget {
  const TranslateExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TranslateExportProvider(),
      child: const _TranslateExportView(),
    );
  }
}

class _TranslateExportView extends StatefulWidget {
  const _TranslateExportView();

  @override
  State<_TranslateExportView> createState() => _TranslateExportViewState();
}

class _TranslateExportViewState extends State<_TranslateExportView> {
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProducts());
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final userId = context.read<AuthProvider>().userId;
    final provider = context.read<TranslateExportProvider>();
    await provider.loadProducts(userId);
    if (!mounted) return;
    if (provider.errorMessage != null) {
      AppSnackbar.error(context, provider.errorMessage!);
      provider.clearError();
    }
  }

  Future<void> _translate() async {
    final provider = context.read<TranslateExportProvider>();
    await provider.translate(sourceNotes: _notesController.text);
    if (!mounted) return;
    if (provider.errorMessage != null) {
      AppSnackbar.error(context, provider.errorMessage!);
      provider.clearError();
      return;
    }
    AppSnackbar.success(context, 'Terjemahan siap. Cek ID, EN, AR, dan ZH.');
  }

  Future<void> _exportJson() async {
    final provider = context.read<TranslateExportProvider>();
    await provider.exportJson();
    if (!mounted) return;
    if (provider.errorMessage != null) {
      AppSnackbar.error(context, provider.errorMessage!);
      provider.clearError();
    }
  }

  Future<void> _exportText() async {
    final provider = context.read<TranslateExportProvider>();
    await provider.exportText();
    if (!mounted) return;
    if (provider.errorMessage != null) {
      AppSnackbar.error(context, provider.errorMessage!);
      provider.clearError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final padding = Responsive.horizontalPadding(context);
    final state = context.watch<TranslateExportProvider>();
    final bundle = state.bundle;
    final activeCopy = bundle?.of(state.activeLanguage);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Terjemah & Ekspor'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: state.isLoadingProducts
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(padding, 16, padding, 32),
              children: [
                Text(
                  'Terjemahkan deskripsi produk ke Indonesia, English, Arab, dan Mandarin, lalu ekspor untuk marketplace.',
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 16),
                if (state.products.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      'Belum ada produk. Daftarkan produk di Menu → Produk dulu.',
                      style: AppTextStyles.bodyMedium,
                    ),
                  )
                else ...[
                  TranslateProductPicker(
                    products: state.products,
                    selected: state.selectedProduct,
                    enabled: !state.isTranslating,
                    onSelected: state.selectProduct,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    enabled: !state.isTranslating,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Catatan / deskripsi tambahan (opsional)',
                      hintText: 'Contoh: rasa pedas, kemasan 100 gram, homemade',
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: state.canTranslate ? _translate : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF06B6D4),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: state.isTranslating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.textOnPrimary,
                              ),
                            )
                          : const Icon(Icons.translate_rounded),
                      label: Text(
                        state.isTranslating
                            ? 'Menerjemahkan...'
                            : 'Terjemahkan ke ID · EN · AR · ZH',
                        style: AppTextStyles.labelLarge,
                      ),
                    ),
                  ),
                ],
                if (bundle != null && activeCopy != null) ...[
                  const SizedBox(height: 24),
                  Text('Hasil terjemahan', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 10),
                  TranslateLanguageTabs(
                    selected: state.activeLanguage,
                    onSelected: state.setActiveLanguage,
                  ),
                  const SizedBox(height: 12),
                  TranslateResultCard(
                    language: state.activeLanguage,
                    copy: activeCopy,
                  ),
                  const SizedBox(height: 16),
                  Text('Ekspor', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'JSON memakai skema sello.product_i18n@${ProductTranslationBundle.schemaVersion}.',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  TranslateExportActions(
                    enabled: true,
                    isExporting: state.isExporting,
                    onExportJson: _exportJson,
                    onExportText: _exportText,
                  ),
                ],
              ],
            ),
    );
  }
}
