import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:andril_mobile/app/themes/common/chat_theme.dart';
import 'package:andril_mobile/features/common/virtual_gifts/domain/gift_catalogs.dart';

class CoinDot extends StatelessWidget {
  final double diameter;
  const CoinDot({super.key, this.diameter = 11});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFEE9300), width: 0.6),
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.5),
          colors: [Color(0xFFFFEAB0), Color(0xFFF5B10C), Color(0xFFE88B00)],
          stops: [0, 0.58, 1],
        ),
      ),
    );
  }
}

/// Exact reproduction of the HTML reference compact 5×2 Virtual Gift Picker Sheet.
/// Supports module-specific gift catalogs and theme palettes.
class GiftPickerSheet extends StatelessWidget {
  final int balance;
  final ValueChanged<AndrilGift> onGiftTap;
  final VoidCallback onBuyCoins;
  final List<AndrilGift> giftCatalog;
  final AndrilChatTheme theme;

  const GiftPickerSheet({
    super.key,
    required this.balance,
    required this.onGiftTap,
    required this.onBuyCoins,
    this.giftCatalog = socialGifts,
    this.theme = const SocialChatTheme(),
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final tileHeight = width < 360 ? 98.0 : 108.0;
    final desiredHeight = math.min(
      545.0,
      math.max(390.0, media.size.height * 0.68),
    );

    return Container(
      key: const Key('gift_picker_sheet'),
      height: desiredHeight,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x33204A41),
            blurRadius: 35,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 44,
              height: 4.5,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFD2DCD7),
                borderRadius: BorderRadius.circular(8),
              ),
            ),

            // Header matching HTML: <h2>Virtual Gifts</h2> + Coin balance + Close btn
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Virtual Gifts',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: theme.primary,
                      letterSpacing: -0.7,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF4E8),
                    border: Border.all(color: const Color(0xFFF1D8B4)),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CoinDot(diameter: 12),
                      const SizedBox(width: 5),
                      Text(
                        '$balance Coins',
                        key: const Key('coin_balance'),
                        style: const TextStyle(
                          color: Color(0xFF8B4D08),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  key: const Key('close_gifts'),
                  tooltip: 'Close virtual gifts',
                  icon: Icon(Icons.close, color: theme.primary, size: 24),
                  onPressed: () => Navigator.of(context).pop(),
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 36,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Exact 5-column × 2-row grid matching HTML
            Expanded(
              child: GridView.builder(
                key: const Key('gift_grid'),
                physics: const ClampingScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 6,
                  mainAxisExtent: tileHeight,
                ),
                itemCount: giftCatalog.length,
                itemBuilder: (context, index) {
                  final gift = giftCatalog[index];
                  return Semantics(
                    button: true,
                    label: 'Send ${gift.name}, ${gift.coins} coins',
                    child: Material(
                      color: theme.giftTile,
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        key: Key('gift_tile_$index'),
                        onTap: () => onGiftTap(gift),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2EFED)),
                          ),
                          padding: const EdgeInsets.fromLTRB(2, 4, 2, 6),
                          child: Column(
                            children: [
                              Expanded(
                                child: Image.asset(
                                  gift.assetPath,
                                  key: Key('gift_image_$index'),
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CoinDot(diameter: 10),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${gift.coins}',
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      color: Color(0xFF151F24),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Footer matching HTML: Tap hint + Buy Coins button
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      'Tap a gift to view details',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      key: const Key('buy_coins'),
                      onPressed: onBuyCoins,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                      ),
                      child: const Text(
                        'Buy Coins',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
