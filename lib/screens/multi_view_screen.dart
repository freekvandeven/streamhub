import "package:flutter_hooks/flutter_hooks.dart";
import "package:go_router/go_router.dart";
import "package:material_ui/material_ui.dart";
import "package:streamhub/hooks/video_hooks.dart";
import "package:streamhub/models/channel.dart";
import "package:streamhub/widgets/channel_picker.dart";
import "package:streamhub/widgets/stream_pane.dart";

/// Most streams the split screen shows at once
const _maxStreams = 4;

/// A stream in the split screen. The id keeps its player alive when other
/// streams are removed.
typedef _Stream = ({int id, Channel channel});

/// Watch up to four streams at once. Two streams sit side by side on wide
/// screens and above each other on narrow ones; more form a 2x2 grid.
class MultiViewScreen extends HookWidget {
  const MultiViewScreen({required this.initialChannels, super.key});

  final List<Channel> initialChannels;

  @override
  Widget build(BuildContext context) {
    final streams = useState<List<_Stream>>(
      useMemoized(
        () => [
          for (final (index, channel) in initialChannels.take(_maxStreams).indexed) (id: index, channel: channel),
        ],
      ),
    );
    final nextId = useRef(streams.value.length);
    final activeId = useState(streams.value.firstOrNull?.id);

    useWakelock();
    useAllowLandscape();

    Future<void> addStream() async {
      final channel = await showChannelPicker(context);
      if (channel == null || !context.mounted) return;

      final stream = (id: nextId.value++, channel: channel);
      streams.value = [...streams.value, stream];
      activeId.value ??= stream.id;
    }

    void removeStream(int id) {
      streams.value = [
        for (final stream in streams.value)
          if (stream.id != id) stream,
      ];
      if (activeId.value == id) activeId.value = streams.value.firstOrNull?.id;
    }

    final count = streams.value.length;
    // Two cells until there are more than two streams, then a 2x2 grid
    final cellCount = count <= 2 ? 2 : _maxStreams;
    final cells = [
      for (final stream in streams.value)
        StreamPane(
          key: ValueKey(stream.id),
          channel: stream.channel,
          isActive: stream.id == activeId.value,
          onActivate: () => activeId.value = stream.id,
          onRemove: () => removeStream(stream.id),
          onOpen: () => context.pushReplacement("/video-player", extra: stream.channel),
        ),
      for (var i = count; i < cellCount; i++) _AddStreamCell(onPressed: addStream),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text("Split screen"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: "Add stream",
            onPressed: count < _maxStreams ? addStream : null,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          Widget cell(int index) => Expanded(
            child: Padding(padding: const EdgeInsets.all(1), child: cells[index]),
          );

          if (cells.length == 2) {
            final sideBySide = constraints.maxWidth >= constraints.maxHeight;
            return Flex(
              direction: sideBySide ? Axis.horizontal : Axis.vertical,
              children: [cell(0), cell(1)],
            );
          }
          return Column(
            children: [
              for (var row = 0; row < 2; row++)
                Expanded(
                  child: Row(children: [cell(row * 2), cell(row * 2 + 1)]),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AddStreamCell extends StatelessWidget {
  const _AddStreamCell({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF161616),
      child: Center(
        child: FilledButton.tonalIcon(
          onPressed: onPressed,
          icon: const Icon(Icons.add),
          label: const Text("Add channel"),
        ),
      ),
    );
  }
}
