import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../vehicles/presentation/vehicle_providers.dart';
import '../../drivers/presentation/driver_providers.dart';
import '../../customers/presentation/customer_providers.dart';
import '../domain/document_entity.dart';
import 'document_providers.dart';

class DocumentFormScreen extends ConsumerStatefulWidget {
  final String? documentId;

  const DocumentFormScreen({super.key, this.documentId});

  @override
  ConsumerState<DocumentFormScreen> createState() => _DocumentFormScreenState();
}

class _DocumentFormScreenState extends ConsumerState<DocumentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _numberController;
  late TextEditingController _notesController;

  String _category = 'company';
  String _type = 'gst_certificate';
  String? _selectedEntityId;
  String? _selectedEntityName;

  bool _hasExpiry = true;
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 365));

  bool _initialized = false;

  // File Picker simulator state
  bool _fileAttached = false;
  String _fileName = '';
  String _fileSizeStr = '';
  int _fileSize = 0;
  String _mimeType = '';
  Uint8List? _mockBytes;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _numberController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _initializeValues(List<DocumentEntity> list) {
    if (_initialized) return;
    if (widget.documentId != null) {
      final doc = list.firstWhere((d) => d.id == widget.documentId);
      _nameController.text = doc.fileName;
      _numberController.text = doc.documentNumber;
      _notesController.text = doc.notes ?? '';
      _category = doc.category;
      _type = doc.type;
      _selectedEntityId = doc.relatedEntityId;
      _selectedEntityName = doc.entityName;
      _fileAttached = doc.downloadUrl.isNotEmpty;
      _fileSize = doc.fileSize;
      _fileSizeStr = '${(doc.fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
      _mimeType = doc.mimeType;
      _fileName = doc.originalFileName;
      if (doc.expiryDate != null) {
        _hasExpiry = true;
        _expiryDate = doc.expiryDate!;
      } else {
        _hasExpiry = false;
      }
    }
    _initialized = true;
  }

  void _simulateFileSelection(String extension) {
    setState(() {
      _fileAttached = true;
      final typeLabel = _type.replaceAll('_', '');
      _fileName = 'doc_${typeLabel}_${math.Random().nextInt(999)}.$extension';

      // Random size up to 12MB to test size validations
      final isLarge = math.Random().nextBool() &&
          math.Random().nextBool(); // 25% chance of large file
      final mb = isLarge
          ? (math.Random().nextDouble() * 5 + 10.1)
          : (math.Random().nextDouble() * 3 + 0.2);
      _fileSize = (mb * 1024 * 1024).toInt();
      _fileSizeStr = '${mb.toStringAsFixed(1)} MB';

      switch (extension) {
        case 'png':
          _mimeType = 'image/png';
          break;
        case 'jpg':
          _mimeType = 'image/jpeg';
          break;
        case 'docx':
          _mimeType =
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          break;
        case 'xlsx':
          _mimeType =
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
          break;
        case 'pdf':
        default:
          _mimeType = 'application/pdf';
          break;
      }

      _mockBytes = Uint8List.fromList(List.generate(100, (i) => i));
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_fileAttached) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please upload or drag a file to the dropzone first.')),
      );
      return;
    }

    final doc = DocumentEntity(
      id: widget.documentId ?? '',
      companyId: '', // Filled in controller
      relatedEntityId: _category == 'company' ? null : _selectedEntityId,
      relatedEntityType: _category == 'company' ? null : _category,
      entityName: _category == 'company' ? null : _selectedEntityName,
      category: _category,
      type: _type,
      fileName: _nameController.text.trim(),
      originalFileName: _fileName,
      fileSize: _fileSize,
      mimeType: _mimeType,
      storagePath: 'documents/$_fileName',
      downloadUrl: widget.documentId != null
          ? 'https://mock-url/$_fileName'
          : '', // populated by upload
      uploadDate: DateTime.now(),
      expiryDate: _hasExpiry ? _expiryDate : null,
      status: 'pending_verification',
      notes: _notesController.text.trim(),
      uploadedBy: '', // Filled in controller
      documentNumber: _numberController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await ref
        .read(documentFormControllerProvider.notifier)
        .saveDocument(doc, fileBytes: _mockBytes);

    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final formState = ref.watch(documentFormControllerProvider);
    final documents = ref.watch(documentsStreamProvider).valueOrNull ?? [];
    final vehicles = ref.watch(vehiclesStreamProvider).valueOrNull ?? [];
    final drivers = ref.watch(driversStreamProvider).valueOrNull ?? [];
    final customers = ref.watch(customersStreamProvider).valueOrNull ?? [];

    if (widget.documentId != null && documents.isNotEmpty) {
      _initializeValues(documents);
    }

    final isEditMode = widget.documentId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Modify Vault Metadata' : 'New Vault Upload'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditMode
                        ? 'Modify metadata parameters'
                        : 'Drag & Drop files to verify and upload to company vault',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onBackground.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 1. Drag & Drop Mock Dropzone Visual Area
                  Text('Document File Input',
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      // Trigger file picker dialog sheet
                      showModalBottomSheet<void>(
                        context: context,
                        builder: (ctx) => SafeArea(
                          child: Wrap(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.picture_as_pdf,
                                    color: Colors.red),
                                title: const Text('Pick PDF Document'),
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                  _simulateFileSelection('pdf');
                                },
                              ),
                              ListTile(
                                leading:
                                    const Icon(Icons.image, color: Colors.blue),
                                title: const Text('Pick PNG/JPG Image'),
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                  _simulateFileSelection('png');
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.table_view_outlined,
                                    color: Colors.green),
                                title:
                                    const Text('Pick Excel Spreadsheet (XLSX)'),
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                  _simulateFileSelection('xlsx');
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _fileAttached
                            ? colorScheme.primary.withOpacity(0.04)
                            : colorScheme.surfaceVariant.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _fileAttached
                              ? colorScheme.primary
                              : colorScheme.outline.withOpacity(0.3),
                          style: BorderStyle.solid,
                          width: _fileAttached ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: _fileAttached
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _mimeType == 'application/pdf'
                                        ? Icons.picture_as_pdf
                                        : (_mimeType.startsWith('image')
                                            ? Icons.image
                                            : Icons.table_view_outlined),
                                    size: 48,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _fileName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                      'Size: $_fileSizeStr | Format: ${_mimeType.toUpperCase()}'),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.cloud_download_outlined,
                                      size: 48, color: Colors.grey),
                                  const SizedBox(height: 8),
                                  const Text('Click or Drag & Drop File Here'),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Supports: PDF, JPG, PNG, DOCX, XLSX (Max 10MB)',
                                    style: TextStyle(
                                        color: colorScheme.onSurfaceVariant
                                            .withOpacity(0.6),
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. Category Selector
                  Text('Document Category', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(
                          value: 'company',
                          child: Text('Company Level Document')),
                      DropdownMenuItem(
                          value: 'vehicle',
                          child: Text('Vehicle Compliance Document')),
                      DropdownMenuItem(
                          value: 'driver',
                          child: Text('Driver Licensing / Certificate')),
                      DropdownMenuItem(
                          value: 'customer',
                          child: Text('Customer Agreements & KYC')),
                      DropdownMenuItem(
                          value: 'finance',
                          child: Text('Finance Invoices & Bills')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _category = val;
                          _selectedEntityId = null;
                          _selectedEntityName = null;
                          // Set default type
                          if (val == 'company') _type = 'gst_certificate';
                          if (val == 'vehicle') _type = 'rc';
                          if (val == 'driver') _type = 'driving_license';
                          if (val == 'customer') _type = 'contract';
                          if (val == 'finance') _type = 'invoice';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // 3. Type Selector
                  Text('Document Type', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _type,
                    decoration:
                        const InputDecoration(border: OutlineInputBorder()),
                    items: _getTypeOptions(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _type = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // 4. Associated Entity Selector
                  if (_category == 'vehicle') ...[
                    Text('Associated Vehicle',
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedEntityId,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Select Vehicle'),
                      items: vehicles
                          .map((v) => DropdownMenuItem(
                                value: v.id,
                                child: Text(
                                    '${v.licensePlate} (${v.make} ${v.model})'),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final vObj =
                              vehicles.firstWhere((veh) => veh.id == val);
                          setState(() {
                            _selectedEntityId = val;
                            _selectedEntityName = vObj.licensePlate;
                          });
                        }
                      },
                      validator: (value) =>
                          value == null ? 'Please select a vehicle' : null,
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (_category == 'driver') ...[
                    Text('Associated Driver',
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedEntityId,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Select Driver'),
                      items: drivers
                          .map((d) => DropdownMenuItem(
                                value: d.id,
                                child: Text(d.fullName),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final dObj =
                              drivers.firstWhere((drv) => drv.id == val);
                          setState(() {
                            _selectedEntityId = val;
                            _selectedEntityName = dObj.fullName;
                          });
                        }
                      },
                      validator: (value) =>
                          value == null ? 'Please select a driver' : null,
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (_category == 'customer') ...[
                    Text('Associated Customer',
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedEntityId,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Select Customer'),
                      items: customers
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          final cObj =
                              customers.firstWhere((cust) => cust.id == val);
                          setState(() {
                            _selectedEntityId = val;
                            _selectedEntityName = cObj.name;
                          });
                        }
                      },
                      validator: (value) =>
                          value == null ? 'Please select a customer' : null,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 5. Basic Metadata Form
                  Text('Document Display Name',
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'e.g. GST Certificate 2026, Volvo RC',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Document name is required'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  Text('Document Reference Number',
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _numberController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'e.g. GSTIN, DL Number, Policy #',
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Reference number is required'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Expiration tracking
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Tracks Expiration Date',
                          style: theme.textTheme.titleSmall),
                      Switch(
                        value: _hasExpiry,
                        onChanged: (val) => setState(() => _hasExpiry = val),
                      ),
                    ],
                  ),
                  if (_hasExpiry) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 54)),
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                          'Expiry Date: ${DateFormat('yMMMd').format(_expiryDate)}'),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _expiryDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2040),
                        );
                        if (picked != null) {
                          setState(() {
                            _expiryDate = picked;
                          });
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Notes
                  Text('Notes', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText:
                          'Add audit notes, compliance alerts or reference items...',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 6. Upload progress bar indicator
                  if (formState.isLoading &&
                      formState.uploadProgress > 0.0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Uploading to Cloud Vault...',
                            style: theme.textTheme.bodySmall),
                        Text(
                            '${(formState.uploadProgress * 100).toStringAsFixed(0)}%',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: formState.uploadProgress),
                    const SizedBox(height: 20),
                  ],

                  // 7. Error messages (warnings)
                  if (formState.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colorScheme.error),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: colorScheme.error),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              formState.errorMessage!,
                              style: TextStyle(
                                  color: colorScheme.onErrorContainer,
                                  fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 8. Action button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                    onPressed: formState.isLoading ? null : _submit,
                    child: formState.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(isEditMode
                            ? 'Update Document'
                            : 'Verify & Upload to Vault'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _getTypeOptions() {
    if (_category == 'company') {
      return const [
        DropdownMenuItem(
            value: 'gst_certificate', child: Text('GST Certificate')),
        DropdownMenuItem(value: 'pan', child: Text('PAN Card')),
        DropdownMenuItem(
            value: 'trade_license',
            child: Text('Trade License / Registration')),
        DropdownMenuItem(value: 'company_logo', child: Text('Company Logo')),
        DropdownMenuItem(value: 'other', child: Text('Other')),
      ];
    } else if (_category == 'vehicle') {
      return const [
        DropdownMenuItem(
            value: 'rc', child: Text('Registration Certificate (RC)')),
        DropdownMenuItem(value: 'insurance', child: Text('Insurance Policy')),
        DropdownMenuItem(value: 'fitness', child: Text('Fitness Certificate')),
        DropdownMenuItem(
            value: 'puc', child: Text('Pollution Certificate (PUC)')),
        DropdownMenuItem(value: 'permit', child: Text('Permit')),
        DropdownMenuItem(value: 'road_tax', child: Text('Road Tax Receipt')),
        DropdownMenuItem(value: 'other', child: Text('Other')),
      ];
    } else if (_category == 'driver') {
      return const [
        DropdownMenuItem(
            value: 'driving_license', child: Text('Driving License (DL)')),
        DropdownMenuItem(
            value: 'national_id', child: Text('Aadhaar / National ID')),
        DropdownMenuItem(
            value: 'medical_certificate', child: Text('Medical Certificate')),
        DropdownMenuItem(
            value: 'training_certificate', child: Text('Training Certificate')),
        DropdownMenuItem(value: 'other', child: Text('Other')),
      ];
    } else if (_category == 'customer') {
      return const [
        DropdownMenuItem(value: 'contract', child: Text('Freight Contract')),
        DropdownMenuItem(value: 'agreement', child: Text('SLA / Agreement')),
        DropdownMenuItem(
            value: 'purchase_order', child: Text('Purchase Order (PO)')),
        DropdownMenuItem(
            value: 'kyc_document', child: Text('KYC / Corporate ID')),
        DropdownMenuItem(value: 'other', child: Text('Other')),
      ];
    } else {
      return const [
        DropdownMenuItem(value: 'invoice', child: Text('Invoice')),
        DropdownMenuItem(value: 'receipt', child: Text('Receipt')),
        DropdownMenuItem(value: 'expense_bill', child: Text('Expense Bill')),
        DropdownMenuItem(value: 'payment_proof', child: Text('Payment Proof')),
        DropdownMenuItem(value: 'other', child: Text('Other')),
      ];
    }
  }
}
