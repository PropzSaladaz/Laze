import 'package:flutter/material.dart';
import 'package:laze/presentation/core/themes/dimensions.dart';
import 'package:laze/presentation/core/ui/styled_button.dart';

class IconPicker extends StatefulWidget {
  final IconData? initialIcon;
  final Function(IconData) onIconSelected;

  const IconPicker({
    super.key,
    this.initialIcon,
    required this.onIconSelected,
  });

  @override
  State<IconPicker> createState() => _IconPickerState();
}

class _IconPickerState extends State<IconPicker> {
  late IconData _selectedIcon;

  @override
  void initState() {
    super.initState();
    _selectedIcon = widget.initialIcon ?? Icons.abc;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 10
      ) ,
      child: Padding(
        padding: EdgeInsets.all(Dimens.padding.vertical),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: FractionallySizedBox(
                  alignment: Alignment.centerRight,
                  widthFactor: 1,
                  child: Text(
                    "Choose an Icon",
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                )),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(
                    Icons.close,
                    size: Dimens.icon.medium,
                    color: colorScheme.onSecondary,
                  ),
                )
              ],
            ),
            const SizedBox(
              height: 16,
            ),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 7,
                    mainAxisSpacing: 7),
                itemCount: _iconList.length,
                itemBuilder: (context, index) {
                  final icon = _iconList[index];
                  final isSelected = _selectedIcon == icon;

                  return StyledButton(
                    icon: icon,
                    onPressed: () {
                      widget.onIconSelected(icon);
                      Navigator.of(context).pop();
                    },
                    isClicked: isSelected,
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  // List of most useful icons to be used
  final List<IconData> _iconList = [
    Icons.home,
    Icons.favorite,
    Icons.settings,
    Icons.person,
    Icons.shopping_cart,
    Icons.alarm,
    Icons.book,
    Icons.calendar_today,
    Icons.camera_alt,
    Icons.email,
    Icons.phone,
    Icons.map,
    Icons.music_note,
    Icons.movie,
    Icons.photo,
    Icons.wifi,
    Icons.bluetooth,
    Icons.battery_full,
    Icons.access_alarm,
    Icons.account_balance,
    Icons.account_circle,
    Icons.add_alert,
    Icons.add_a_photo,
    Icons.add_to_photos,
    Icons.airline_seat_flat,
    Icons.airport_shuttle,
    Icons.airplanemode_active,
    Icons.attach_file,
    Icons.attach_money,
    Icons.audiotrack,
    Icons.autorenew,
    Icons.beach_access,
    Icons.brightness_auto,
    Icons.brush,
    Icons.bug_report,
    Icons.business,
    Icons.cake,
    Icons.call,
    Icons.chat,
    Icons.check_circle,
    Icons.cloud,
    Icons.code,
    Icons.collections,
    Icons.computer,
    Icons.content_copy,
    Icons.dashboard,
    Icons.delete,
    Icons.description,
    Icons.devices,
    Icons.directions_bike,
    Icons.directions_car,
    Icons.directions_run,
    Icons.dns,
    Icons.bookmark,
    Icons.build,
    Icons.extension,
    Icons.face,
    Icons.fingerprint,
    Icons.fitness_center,
    Icons.flight,
    Icons.folder,
    Icons.format_paint,
    Icons.free_breakfast,
    Icons.gamepad,
    Icons.headset,
    Icons.help,
    Icons.http,
    Icons.image,
    Icons.keyboard,
    Icons.language,
    Icons.laptop,
    Icons.link,
    Icons.local_dining,
    Icons.local_gas_station,
    Icons.local_grocery_store,
    Icons.local_hospital,
    Icons.local_laundry_service,
    Icons.local_library,
    Icons.mail_outline,
    Icons.message,
    Icons.mic,
    Icons.nature,
    Icons.notifications,
    Icons.palette,
    Icons.pets,
    Icons.play_circle_filled,
    Icons.pool,
    Icons.print,
    Icons.public,
    Icons.restaurant,
    Icons.room,
    Icons.school,
    Icons.security,
    Icons.share,
    Icons.shopping_basket,
    Icons.spa,
    Icons.stars,
    Icons.store,
    Icons.surround_sound,
    Icons.tag_faces,
    Icons.terrain,
    Icons.thumb_up,
    Icons.timer,
    Icons.train,
    Icons.tv,
    Icons.videogame_asset,
    Icons.visibility,
    Icons.work,
    Icons.zoom_in,
  ];
}
