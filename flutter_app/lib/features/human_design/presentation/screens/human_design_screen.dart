import 'package:cosmic_mirror/config/theme/app_palette.dart';
import 'package:cosmic_mirror/features/human_design/domain/entities/human_design.dart';
import 'package:cosmic_mirror/features/human_design/presentation/providers/human_design_providers.dart';
import 'package:cosmic_mirror/features/human_design/presentation/widgets/body_graph.dart';
import 'package:cosmic_mirror/features/human_design/presentation/widgets/center_chip.dart';
import 'package:cosmic_mirror/features/human_design/presentation/widgets/channel_list_tile.dart';
import 'package:cosmic_mirror/features/human_design/presentation/widgets/gate_list.dart';
import 'package:cosmic_mirror/features/human_design/presentation/widgets/incarnation_cross_card.dart';
import 'package:cosmic_mirror/features/human_design/presentation/widgets/type_card.dart';
import 'package:cosmic_mirror/features/human_design/presentation/widgets/variables_strip.dart';
import 'package:cosmic_mirror/l10n/app_localizations.dart';
import 'package:cosmic_mirror/shared/widgets/cosmic_starfield.dart';
import 'package:cosmic_mirror/shared/widgets/error_view.dart';
import 'package:cosmic_mirror/shared/widgets/loading_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HumanDesignScreen extends ConsumerWidget {
  const HumanDesignScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final chartAsync = ref.watch(humanDesignProvider);
    return Scaffold(
      backgroundColor: p.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        title: Text(AppLocalizations.of(context).humanDesignTitle),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CosmicStarfield(
              color: p.textPrimary,
              starCount: 50,
              intensity: 0.6,
            ),
          ),
          chartAsync.when(
            loading: () => const ShimmerList(itemCount: 5),
            error: (e, _) => ErrorView(
              error: e,
              onRetry: () => ref.invalidate(humanDesignProvider),
            ),
            data: (chart) => _Body(chart: chart),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.chart});
  final HumanDesignChart chart;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 100, 20, 16),
              child: TypeCard(chart: chart),
            ),
          ),
          SliverToBoxAdapter(child: _TabBar()),
        ],
        body: TabBarView(
          children: [
            _BodyGraphTab(chart: chart),
            _CentersTab(centers: chart.centers),
            _ChannelsTab(channels: chart.channels),
            _GatesTab(gates: chart.gates),
            _ProfileCrossTab(chart: chart),
          ],
        ),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      decoration: BoxDecoration(
        color: p.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicator: BoxDecoration(
          gradient: p.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.all(4),
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: p.textSecondary,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        tabs: [
          Tab(text: l.humanDesignTabBodyGraph),
          Tab(text: l.humanDesignTabCenters),
          Tab(text: l.humanDesignTabChannels),
          Tab(text: l.humanDesignTabGates),
          Tab(text: l.humanDesignTabProfile),
        ],
      ),
    );
  }
}

class _BodyGraphTab extends StatelessWidget {
  const _BodyGraphTab({required this.chart});
  final HumanDesignChart chart;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use the full available width (minus the ListView padding) so the
        // chart scales up on wider screens. Cap at 480 so it stays
        // proportional on tablets/web.
        final available = constraints.maxWidth - 40;
        final size = available.clamp(280.0, 480.0);
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Center(child: BodyGraph(chart: chart, size: size)),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).humanDesignBodyGraphLegend,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: p.textSecondary,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CentersTab extends StatelessWidget {
  const _CentersTab({required this.centers});
  final List<HDCenter> centers;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [for (final c in centers) CenterCard(center: c)],
    );
  }
}

class _ChannelsTab extends StatelessWidget {
  const _ChannelsTab({required this.channels});
  final List<HDChannel> channels;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (channels.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            AppLocalizations.of(context).humanDesignNoChannels,
            textAlign: TextAlign.center,
            style: TextStyle(color: p.textSecondary),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [for (final ch in channels) ChannelListTile(channel: ch)],
    );
  }
}

class _GatesTab extends StatelessWidget {
  const _GatesTab({required this.gates});
  final List<HDGateActivation> gates;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [GateList(gates: gates)],
    );
  }
}

class _ProfileCrossTab extends StatelessWidget {
  const _ProfileCrossTab({required this.chart});
  final HumanDesignChart chart;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).humanDesignProfileLabel,
                style: TextStyle(
                  color: p.textSecondary,
                  fontSize: 11,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                chart.profile,
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context).humanDesignProfileDesc,
                style: TextStyle(color: p.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IncarnationCrossCard(cross: chart.incarnationCross),
        const SizedBox(height: 12),
        VariablesStrip(variables: chart.variables),
      ],
    );
  }
}
