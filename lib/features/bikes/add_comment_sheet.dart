import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../core/ui/app_snackbar.dart';
import '../../core/validation/validators.dart';
import 'bike_detail_view_model.dart';

class AddCommentSheet extends ConsumerStatefulWidget {
  const AddCommentSheet({super.key, required this.bikeId});

  final String bikeId;

  @override
  ConsumerState<AddCommentSheet> createState() => _AddCommentSheetState();
}

class _AddCommentSheetState extends ConsumerState<AddCommentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final navigator = Navigator.of(context);

    try {
      await ref
          .read(bikeDetailViewModelProvider(widget.bikeId).notifier)
          .addComment(
            title: _titleController.text,
            body: _bodyController.text,
          );

      if (!mounted) return;
      AppSnackbar.showSuccess(context, 'Comment posted');
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final mutation = ref.watch(
      bikeDetailViewModelProvider(widget.bikeId).select((s) => s.mutation),
    );
    final isSubmitting = mutation.isLoading;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Add Comment',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ShadIconButton.ghost(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ShadInputFormField(
              controller: _titleController,
              label: const Text('Title'),
              maxLength: Validators.commentTitleMaxLength,
              validator: Validators.commentTitle,
              enabled: !isSubmitting,
            ),
            const SizedBox(height: 12),
            ShadInputFormField(
              controller: _bodyController,
              label: const Text('Comment'),
              minLines: 3,
              maxLines: 6,
              maxLength: Validators.commentBodyMaxLength,
              validator: Validators.commentBody,
              enabled: !isSubmitting,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ShadButton(
                onPressed: isSubmitting ? null : _submit,
                child: Text(isSubmitting ? 'Posting…' : 'Post'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
