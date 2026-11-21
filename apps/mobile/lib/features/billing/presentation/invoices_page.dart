import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:ticketsur/app/navigation.dart';
import 'package:ticketsur/app/routes.dart';
import 'package:ticketsur/design_system/brand_pdf.dart';
import 'package:ticketsur/design_system/components/cards.dart';
import 'package:ticketsur/design_system/components/controls.dart';
import 'package:ticketsur/design_system/components/hero_header.dart';
import 'package:ticketsur/design_system/components/tiles.dart';
import 'package:ticketsur/design_system/tikeo_tints.dart';
import 'package:ticketsur/design_system/tikeo_tokens.dart';
import 'package:ticketsur/design_system/widgets/skeleton.dart';
import 'package:ticketsur/design_system/widgets/toaster.dart';
import 'package:ticketsur/features/billing/application/billing_providers.dart';
import 'package:ticketsur/features/billing/domain/billing.dart';
import 'package:ticketsur/features/billing/domain/billing_admin.dart';
import 'package:ticketsur/features/billing/presentation/billing_copy.dart';
import 'package:ticketsur/features/billing/presentation/my_pack_page.dart';
import 'package:ticketsur/features/tickets/application/ticket_providers.dart';
import 'package:ticketsur/features/tickets/presentation/ticket_pdf.dart'
    show pdfSafe;
import 'package:ticketsur/l10n/l10n.dart';

/// Filtre de la liste des factures (P7).
enum InvoiceFilter { all, toPay, paid }

/// Lignes « Factures et reçus » : factures à l'usage et reçus de forfait,
/// les plus récents d'abord. [limit] : nombre de lignes au plus.
List<Widget> billingHistoryRows(
  BuildContext context,
  MyBilling billing, {
  InvoiceFilter filter = InvoiceFilter.all,
  int? limit,
}) {
  final l10n = context.l10n;
  final tints = context.tints;
  final rows = <(DateTime, Widget)>[
    for (final invoice in billing.invoices)
      if (switch (filter) {
        InvoiceFilter.all => true,
        InvoiceFilter.toPay => !invoice.paid,
        InvoiceFilter.paid => invoice.paid,
      })
        (
          invoice.issuedAt,
          TikeoListRow(
            key: Key('billing-invoice-${invoice.id}'),
            stripe: invoiceTint(context, invoice).icon,
            title: invoice.eventTitle,
            lines: [
              l10n.billingInvoiceEntries(invoice.entries),
              billingDate(invoice.issuedAt),
            ],
            badge: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                TikeoPill(label: money(l10n, invoice.amount), tint: tints.gray),
                TikeoPill(
                  label: invoiceStatusLabel(l10n, invoice),
                  tint: invoiceTint(context, invoice),
                ),
              ],
            ),
            onTap: () =>
                unawaited(context.push(AppRoutes.billingInvoice(invoice.id))),
          ),
        ),
    if (filter != InvoiceFilter.toPay)
      for (final request in billing.requests)
        if (request.status == RequestStatus.activated)
          (
            request.createdAt,
            TikeoListRow(
              key: Key('billing-receipt-${request.id}'),
              stripe: tints.green.icon,
              title: request.addonsOnly
                  ? l10n.billingReceiptAddons
                  : l10n.billingReceiptPack,
              lines: [
                l10n.billingReferenceLine(
                  request.reference,
                  billingDate(request.createdAt),
                ),
              ],
              badge: TikeoPill(
                label: money(l10n, request.amount),
                tint: tints.green,
              ),
              onTap: () =>
                  unawaited(context.push(AppRoutes.billingRequest(request.id))),
            ),
          ),
  ]..sort((a, b) => b.$1.compareTo(a.$1));
  if (rows.isEmpty) {
    return [
      Text(
        l10n.billingInvoicesEmpty,
        key: const Key('billing-invoices-empty'),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ];
  }
  return [
    for (final (_, row) in rows.take(limit ?? rows.length))
      Padding(padding: const EdgeInsets.only(bottom: 8), child: row),
  ];
}

String invoiceStatusLabel(AppLocalizations l10n, MyInvoice invoice) =>
    invoice.paid
    ? l10n.billingStatusPaid
    : invoice.overdue
    ? l10n.billingInvoiceOverdue
    : l10n.billingInvoiceToPay;

TikeoTint invoiceTint(BuildContext context, MyInvoice invoice) {
  final tints = context.tints;
  return invoice.paid
      ? tints.green
      : invoice.overdue
      ? tints.red
      : tints.amber;
}

/// Détail d'une facture : (libellé, montant) par ligne de calcul.
List<(String, int)> invoiceRows(AppLocalizations l10n, MyInvoice invoice) => [
  for (final line in invoice.lines)
    switch (line.kind) {
      'tier' => (
        l10n.billingLineTier(
          line.from ?? 0,
          line.to ?? 0,
          money(l10n, line.price),
        ),
        line.amount,
      ),
      'addon' => (
        l10n.billingLineAddon(
          line.option?.label(l10n) ?? '—',
          line.count,
          money(l10n, line.price),
        ),
        line.amount,
      ),
      _ => (
        l10n.billingLineEntries(line.count, money(l10n, line.price)),
        line.amount,
      ),
    },
];

/// P7 · Factures et reçus.
class InvoicesPage extends ConsumerStatefulWidget {
  const new({this.initial = InvoiceFilter.all, super.key});

  final InvoiceFilter initial;

  @override
  ConsumerState<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends ConsumerState<InvoicesPage> {
  late InvoiceFilter _filter = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final billing = ref.watch(myBillingProvider);
    return Scaffold(
      appBar: TikeoAppBar(
        title: Text(l10n.billingInvoicesTitle),
        leading: BackButton(onPressed: () => context.popOr(AppRoutes.billing)),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myBillingProvider.future),
        child: ListView(
          key: const Key('billing-invoices-page'),
          padding: EdgeInsets.fromLTRB(
            TikeoSizes.screenMargin,
            TikeoSizes.cardGap,
            TikeoSizes.screenMargin,
            MediaQuery.paddingOf(context).bottom + TikeoSizes.sectionGap,
          ),
          children: [
            StatusTabs<InvoiceFilter>(
              values: InvoiceFilter.values,
              selected: _filter,
              keyOf: (value) => Key('billing-invoices-filter-${value.name}'),
              labelOf: (value) => switch (value) {
                InvoiceFilter.all => l10n.billingFilterAllInvoices,
                InvoiceFilter.toPay => l10n.billingInvoiceToPay,
                InvoiceFilter.paid => l10n.billingFilterPaid,
              },
              onSelected: (value) => setState(() => _filter = value),
            ),
            const SizedBox(height: TikeoSizes.cardGap),
            ...switch (billing) {
              AsyncValue(:final MyBilling value) => billingHistoryRows(
                context,
                value,
                filter: _filter,
              ),
              AsyncValue(:final error?) => [
                TintedBanner(
                  tint: context.tints.red,
                  icon: Icons.cloud_off_rounded,
                  title: promoterBillingMessage(l10n, error),
                ),
              ],
              _ => [
                const Shimmer(
                  child: SkeletonBox(height: 240, radius: TikeoRadii.card),
                ),
              ],
            },
          ],
        ),
      ),
    );
  }
}

/// P7 · Détail d'une facture à l'usage : calcul, échéance, paiement, PDF.
class InvoiceDetailPage extends ConsumerStatefulWidget {
  const new({required this.invoiceId, super.key});

  final String invoiceId;

  @override
  ConsumerState<InvoiceDetailPage> createState() => _InvoiceDetailPageState();
}

class _InvoiceDetailPageState extends ConsumerState<InvoiceDetailPage> {
  bool _sharing = false;

  Future<void> _copy(String text) async {
    final toast = Toaster.of(context);
    final l10n = context.l10n;
    await Clipboard.setData(ClipboardData(text: text));
    toast.info(l10n.billingCopied);
  }

  Future<void> _pdf(MyInvoice invoice) async {
    final l10n = context.l10n;
    final toast = Toaster.of(context);
    final share = ref.read(shareFilesProvider);
    setState(() => _sharing = true);
    try {
      final bytes = await buildInvoicePdf(
        l10n,
        invoice: invoice,
        logo: await loadPdfLogo(),
      );
      await share([
        (
          bytes: bytes,
          name: 'Facture-${invoice.reference}.pdf',
          mimeType: 'application/pdf',
        ),
      ]);
    } on Object {
      toast.error(l10n.billingErrorLoad);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final billing = ref.watch(myBillingProvider);
    final invoice = billing.value?.invoiceById(widget.invoiceId);
    return Scaffold(
      appBar: TikeoAppBar(
        title: Text(l10n.billingInvoiceTitle),
        leading: BackButton(
          onPressed: () => context.popOr(AppRoutes.billingInvoices),
        ),
      ),
      body: SelectionArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            TikeoSizes.screenMargin,
            TikeoSizes.cardGap,
            TikeoSizes.screenMargin,
            MediaQuery.paddingOf(context).bottom + TikeoSizes.sectionGap,
          ),
          child: switch ((billing.value, invoice)) {
            (final MyBilling value, final MyInvoice invoice) => _content(
              context,
              value,
              invoice,
            ),
            (final MyBilling _, null) => Text(
              l10n.billingInvoiceMissing,
              key: const Key('billing-invoice-missing'),
            ),
            _ when billing.hasError => TintedBanner(
              tint: context.tints.red,
              icon: Icons.cloud_off_rounded,
              title: promoterBillingMessage(l10n, billing.error!),
            ),
            _ => const Shimmer(
              child: SkeletonBox(height: 320, radius: TikeoRadii.card),
            ),
          },
        ),
      ),
    );
  }

  Widget _content(BuildContext context, MyBilling billing, MyInvoice invoice) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tints = context.tints;
    final payment = billing.payment;
    Widget row(String label, String amount, {Key? key, bool strong = false}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: strong
                      ? theme.textTheme.titleMedium
                      : theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  amount,
                  key: key,
                  textAlign: TextAlign.end,
                  style: strong
                      ? TikeoTextStyles.tileNumber.copyWith(
                          color: tints.mint.text,
                        )
                      : theme.textTheme.labelLarge,
                ),
              ),
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TintedBanner(
          key: Key(
            'billing-invoice-state-${invoice.paid
                ? 'paid'
                : invoice.overdue
                ? 'overdue'
                : 'due'}',
          ),
          tint: invoiceTint(context, invoice),
          icon: invoice.paid
              ? Icons.verified_rounded
              : invoice.overdue
              ? Icons.warning_rounded
              : Icons.schedule_rounded,
          title: invoiceStatusLabel(l10n, invoice),
          body: invoice.paid
              ? l10n.billingPaidOn(billingDate(invoice.paidAt ?? invoice.dueAt))
              : invoice.overdue
              ? '${l10n.billingDueOn(billingDate(invoice.dueAt))} · '
                    '${l10n.billingOverdueBody}'
              : l10n.billingDueOn(billingDate(invoice.dueAt)),
        ),
        const SizedBox(height: TikeoSizes.cardGap),
        TikeoCard(
          key: const Key('billing-invoice-detail'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(invoice.eventTitle, style: theme.textTheme.titleLarge),
              Text(
                [
                  ?invoice.packName,
                  l10n.billingIssuedOn(billingDate(invoice.issuedAt)),
                  invoice.reference,
                ].join(' · '),
                style: theme.textTheme.bodySmall,
              ),
              const Divider(height: 24),
              row(l10n.billingInvoiceEntries(invoice.entries), ''),
              if (invoice.freeEntries > 0)
                row(
                  l10n.billingFreeEntries(invoice.freeEntries),
                  money(l10n, 0),
                ),
              for (final (label, amount) in invoiceRows(l10n, invoice))
                row(label, money(l10n, amount)),
              const Divider(height: 24),
              row(
                l10n.billingTotal,
                money(l10n, invoice.amount),
                key: const Key('billing-invoice-total'),
                strong: true,
              ),
            ],
          ),
        ),
        if (!invoice.paid) ...[
          const SizedBox(height: TikeoSizes.sectionGap),
          SectionHeader(
            title: l10n.billingHowToPay,
            icon: Icons.send_to_mobile_rounded,
          ),
          const SizedBox(height: 8),
          TikeoCard(
            key: const Key('billing-invoice-pay'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.billingReferenceToGive,
                  style: theme.textTheme.bodySmall,
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        invoice.reference,
                        key: const Key('billing-invoice-reference'),
                        style: TikeoTextStyles.ticketNumber.copyWith(
                          fontSize: 22,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.billingCopy,
                      onPressed: () => unawaited(_copy(invoice.reference)),
                      icon: const Icon(Icons.copy_rounded),
                    ),
                  ],
                ),
                for (final (channel, number) in [
                  (PaymentChannel.orangeMoney, payment.orangeMoneyNumber),
                  (PaymentChannel.moovMoney, payment.moovMoneyNumber),
                ])
                  SettingsRow(
                    key: Key('billing-invoice-pay-${channel.wireName}'),
                    icon: Icons.phone_android_rounded,
                    tint: channel == PaymentChannel.orangeMoney
                        ? tints.orange
                        : tints.blue,
                    title: channelLabel(l10n, channel),
                    subtitle: number ?? l10n.billingNumberMissing,
                    trailing: number == null
                        ? null
                        : IconButton(
                            tooltip: l10n.billingCopy,
                            onPressed: () => unawaited(_copy(number)),
                            icon: const Icon(Icons.copy_rounded),
                          ),
                  ),
                const SizedBox(height: 4),
                Text(
                  l10n.billingInvoicePayHint,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: TikeoSizes.cardGap),
        TikeoPrimaryButton(
          key: const Key('billing-invoice-pdf'),
          busy: _sharing,
          onPressed: _sharing ? null : () => unawaited(_pdf(invoice)),
          icon: Icons.picture_as_pdf_rounded,
          label: l10n.billingDownloadPdf,
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: const Key('billing-invoice-support'),
          onPressed: () => unawaited(context.push(AppRoutes.supportNew)),
          icon: const Icon(Icons.support_agent_rounded),
          label: Text(l10n.billingContactSupport),
        ),
      ],
    );
  }
}

/// Facture à l'usage en PDF (A4), aux couleurs de Tikéo.
Future<Uint8List> buildInvoicePdf(
  AppLocalizations l10n, {
  required MyInvoice invoice,
  Uint8List? logo,
}) async {
  final mark = logo == null ? null : pw.MemoryImage(logo);
  String m(int amount) => pdfSafe(money(l10n, amount));
  const small = pw.TextStyle(fontSize: 9, color: BrandPdf.muted);
  const body = pw.TextStyle(fontSize: 10);
  final doc = pw.Document(
    title: pdfSafe('${l10n.billingInvoiceTitle} ${invoice.reference}'),
    creator: 'Tikeo',
  );
  pw.Widget line(String label, String amount, {bool strong = false}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 4),
        child: pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                pdfSafe(label),
                style: strong
                    ? const pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      )
                    : body,
              ),
            ),
            pw.Text(
              amount,
              style: strong
                  ? const pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: BrandPdf.mintDeep,
                    )
                  : body,
            ),
          ],
        ),
      );
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: const pw.BoxDecoration(
              color: BrandPdf.navy,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        pdfSafe(l10n.billingInvoiceTitle).toUpperCase(),
                        style: const pw.TextStyle(
                          color: BrandPdf.mint,
                          fontSize: 9,
                          letterSpacing: 1.5,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        pdfSafe(invoice.eventTitle),
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        pdfSafe(
                          [
                            invoice.reference,
                            ?invoice.packName,
                            l10n.billingIssuedOn(billingDate(invoice.issuedAt)),
                          ].join(' - '),
                        ),
                        style: const pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
                pdfBrandMark(mark, height: 22),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          line(l10n.billingInvoiceEntries(invoice.entries), ''),
          if (invoice.freeEntries > 0)
            line(l10n.billingFreeEntries(invoice.freeEntries), m(0)),
          for (final (label, amount) in invoiceRows(l10n, invoice))
            line(label, m(amount)),
          pw.Divider(color: BrandPdf.line),
          line(l10n.billingTotal, m(invoice.amount), strong: true),
          pw.SizedBox(height: 12),
          pw.Text(
            pdfSafe(
              invoice.paid
                  ? l10n.billingPaidOn(
                      billingDate(invoice.paidAt ?? invoice.dueAt),
                    )
                  : l10n.billingDueOn(billingDate(invoice.dueAt)),
            ),
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: invoice.paid ? BrandPdf.mintDeep : BrandPdf.spark,
            ),
          ),
          pw.Spacer(),
          pw.Text(pdfSafe(l10n.billingInvoicePdfFooter), style: small),
        ],
      ),
    ),
  );
  return await doc.save();
}
