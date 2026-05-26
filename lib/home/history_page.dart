import 'dart:io';
import 'dart:ui';

import 'package:another_flushbar/flushbar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../helpers/ad_helper.dart';
import '../helpers/history_util.dart';
import 'home_page.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> videos = [];
  bool isLoading = true;

  /// Download
  double progress = 0.0;
  bool isDownloading = false;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  /// ================= LOAD HISTORY =================

  void loadHistory() async {
    setState(() => isLoading = true);

    List<Map<String, dynamic>> list =
    await HistoryUtil.getHistory();

    setState(() {
      videos = list
          .map(
            (e) => e["video"]
        as Map<String, dynamic>,
      )
          .toList();

      isLoading = false;
    });
  }

  /// ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xffF4F7FC,
      ),

      body: Stack(
        children: [
          _bg(),

          SafeArea(
            child: Column(
              children: [
                _header(),

                Expanded(
                  child: isLoading
                      ? const Center(
                    child:
                    CircularProgressIndicator(
                      color: Color(
                        0xff00C853,
                      ),
                    ),
                  )
                      : videos.isEmpty
                      ? _empty()
                      : ListView.builder(
                    padding:
                    const EdgeInsets
                        .all(20),

                    itemCount:
                    videos.length,

                    itemBuilder:
                        (context,
                        index) {
                      final video =
                      videos[
                      index];

                      return _buildVideoCard(
                        video,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          if (isDownloading)
            _buildLoading(),
        ],
      ),
    );
  }

  /// ================= BACKGROUND =================

  Widget _bg() => Stack(
    children: [
      Container(
        decoration:
        const BoxDecoration(
          gradient:
          LinearGradient(
            begin:
            Alignment.topCenter,
            end: Alignment
                .bottomCenter,
            colors: [
              Color(0xffFFFFFF),
              Color(0xffF7FAFC),
              Color(0xffEEF3F8),
            ],
          ),
        ),
      ),

      Positioned(
        top: -120,
        right: -100,
        child: _glow(
          size: 300,
          color: const Color(
            0xff00E676,
          ).withOpacity(.12),
        ),
      ),

      Positioned(
        bottom: -140,
        left: -120,
        child: _glow(
          size: 340,
          color: const Color(
            0xff00C853,
          ).withOpacity(.08),
        ),
      ),

      Positioned.fill(
        child: CustomPaint(
          painter: _GridPainter(
            lineColor:
            const Color(
              0xffDDE5EF,
            ),
          ),
        ),
      ),
    ],
  );

  /// ================= HEADER =================

  Widget _header() => Padding(
    padding:
    const EdgeInsets.fromLTRB(
      20,
      18,
      20,
      10,
    ),
    child: Row(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.pop(
              context,
            );
          },
          child: Container(
            width: 54,
            height: 54,
            decoration:
            BoxDecoration(
              borderRadius:
              BorderRadius
                  .circular(18),
              color:
              Colors.white,
              border: Border.all(
                color:
                const Color(
                  0xffE4EAF2,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withOpacity(
                    .04,
                  ),
                  blurRadius: 20,
                  offset:
                  const Offset(
                    0,
                    8,
                  ),
                ),
              ],
            ),
            child: const Icon(
              Icons
                  .arrow_back_ios_new_rounded,
              color:
              Color(0xff111827),
              size: 20,
            ),
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment
                .start,
            children: [
              ShaderMask(
                shaderCallback:
                    (bounds) {
                  return const LinearGradient(
                    colors: [
                      Color(
                        0xff111827,
                      ),
                      Color(
                        0xff00C853,
                      ),
                    ],
                  ).createShader(
                    bounds,
                  );
                },
                child: const Text(
                  "Video History",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight:
                    FontWeight
                        .w900,
                    color:
                    Colors.white,
                    letterSpacing:
                    -.5,
                  ),
                ),
              ),

              const SizedBox(
                height: 4,
              ),

              const Text(
                "Downloaded & saved videos",
                style: TextStyle(
                  color: Color(
                    0xff6B7280,
                  ),
                  fontSize: 13,
                  fontWeight:
                  FontWeight
                      .w500,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  /// ================= EMPTY =================

  Widget _empty() {
    return Center(
      child: Padding(
        padding:
        const EdgeInsets.symmetric(
          horizontal: 28,
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Container(
              width: 130,
              height: 130,
              decoration:
              BoxDecoration(
                borderRadius:
                BorderRadius
                    .circular(40),
                color: Colors.white,
                border: Border.all(
                  color:
                  const Color(
                    0xffE5EAF1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xff00E676,
                    ).withOpacity(.18),
                    blurRadius: 40,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 58,
                color:
                Color(0xff00C853),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "No History Yet",
              style: TextStyle(
                color:
                Color(0xff111827),
                fontSize: 28,
                fontWeight:
                FontWeight.w900,
              ),
            ),

            const SizedBox(height: 14),

            const Text(
              "Downloaded videos will appear here so you can quickly access and save them again anytime.",
              textAlign:
              TextAlign.center,
              style: TextStyle(
                color:
                Color(0xff6B7280),
                fontSize: 14,
                height: 1.7,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= VIDEO CARD =================

  Widget _buildVideoCard(
      Map<String, dynamic> video,
      ) {
    return Container(
      margin:
      const EdgeInsets.only(
        bottom: 18,
      ),
      decoration: BoxDecoration(
        borderRadius:
        BorderRadius.circular(
          28,
        ),
        color: Colors.white,
        border: Border.all(
          color:
          const Color(
            0xffE5EAF1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(.04),
            blurRadius: 24,
            offset:
            const Offset(
              0,
              10,
            ),
          ),
        ],
      ),
      child: Padding(
        padding:
        const EdgeInsets.all(16),
        child: Row(
          children: [
            video["thumbnail"] !=
                null &&
                video["thumbnail"] !=
                    ""
                ? ClipRRect(
              borderRadius:
              BorderRadius
                  .circular(
                18,
              ),
              child:
              Image.network(
                video[
                "thumbnail"],
                width: 78,
                height: 78,
                fit: BoxFit.cover,
              ),
            )
                : Container(
              width: 78,
              height: 78,
              decoration:
              BoxDecoration(
                borderRadius:
                BorderRadius
                    .circular(
                  18,
                ),
                color:
                const Color(
                  0xffEEF3F8,
                ),
              ),
              child:
              const Icon(
                Icons
                    .videocam_rounded,
                color: Color(
                  0xff00C853,
                ),
                size: 34,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  Text(
                    video["title"] ??
                        "No title",
                    maxLines: 2,
                    overflow:
                    TextOverflow
                        .ellipsis,
                    style:
                    const TextStyle(
                      color: Color(
                        0xff111827,
                      ),
                      fontWeight:
                      FontWeight
                          .w800,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  Container(
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration:
                    BoxDecoration(
                      borderRadius:
                      BorderRadius
                          .circular(
                        14,
                      ),
                      color:
                      const Color(
                        0xffF3FFF7,
                      ),
                    ),
                    child: Text(
                      "Quality: ${video["quality"] ?? "HD"}",
                      style:
                      const TextStyle(
                        color: Color(
                          0xff00A63E,
                        ),
                        fontWeight:
                        FontWeight
                            .w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 14),

            GestureDetector(
              onTap: () async {
                setState(() {
                  isDownloading =
                  true;
                });

                AdHelper.showInterstitial(
                      () async {
                    await downloadVideo(
                      video["url"],
                    );
                  },
                );
              },
              child: Container(
                width: 62,
                height: 62,
                decoration:
                BoxDecoration(
                  borderRadius:
                  BorderRadius
                      .circular(20),
                  gradient:
                  const LinearGradient(
                    colors: [
                      Color(
                        0xff00E676,
                      ),
                      Color(
                        0xff00C853,
                      ),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xff00E676,
                      ).withOpacity(.3),
                      blurRadius: 24,
                      offset:
                      const Offset(
                        0,
                        10,
                      ),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons
                      .download_rounded,
                  color: Colors.black,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= LOADING =================

  Widget _buildLoading() {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 12,
          sigmaY: 12,
        ),
        child: Container(
          color: Colors.white
              .withOpacity(.45),
          child: Center(
            child: Container(
              width: 190,
              padding:
              const EdgeInsets.all(
                24,
              ),
              decoration:
              BoxDecoration(
                borderRadius:
                BorderRadius
                    .circular(34),
                color: Colors.white,
                border: Border.all(
                  color:
                  const Color(
                    0xffE5EAF1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xff00E676,
                    ).withOpacity(.18),
                    blurRadius: 40,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize:
                MainAxisSize.min,
                children: [
                  Stack(
                    alignment:
                    Alignment.center,
                    children: [
                      SizedBox(
                        width: 82,
                        height: 82,
                        child:
                        CircularProgressIndicator(
                          value:
                          progress,
                          strokeWidth:
                          6,
                          backgroundColor:
                          const Color(
                            0xffE8EEF5,
                          ),
                          valueColor:
                          const AlwaysStoppedAnimation(
                            Color(
                              0xff00C853,
                            ),
                          ),
                        ),
                      ),

                      Text(
                        "${(progress * 100).toInt()}%",
                        style:
                        const TextStyle(
                          color: Color(
                            0xff111827,
                          ),
                          fontWeight:
                          FontWeight
                              .w900,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  const Text(
                    "Downloading...",
                    style: TextStyle(
                      color: Color(
                        0xff111827,
                      ),
                      fontWeight:
                      FontWeight
                          .w800,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  const Text(
                    "Preparing ultra fast download",
                    textAlign:
                    TextAlign.center,
                    style: TextStyle(
                      color: Color(
                        0xff6B7280,
                      ),
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  ClipRRect(
                    borderRadius:
                    BorderRadius
                        .circular(
                      30,
                    ),
                    child:
                    LinearProgressIndicator(
                      value:
                      progress,
                      minHeight: 8,
                      backgroundColor:
                      const Color(
                        0xffE8EEF5,
                      ),
                      valueColor:
                      const AlwaysStoppedAnimation(
                        Color(
                          0xff00C853,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ================= GLOW =================

  Widget _glow({
    required double size,
    required Color color,
  }) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration:
        BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: 150,
              spreadRadius: 80,
            ),
          ],
        ),
      ),
    );
  }

  /// ================= PATH =================

  getPathFile() async {
    var now =
        DateTime.now()
            .millisecondsSinceEpoch;

    var dir =
    await getDownloadDirectory();

    return "$dir/$now.mp4";
  }

  Future<String>
  getDownloadDirectory() async {
    final directory = Directory(
      '/storage/emulated/0/Download',
    );

    if (await directory.exists()) {
      return directory.path;
    } else {
      throw Exception(
        "Download folder not found!",
      );
    }
  }

  /// ================= DOWNLOAD =================

  Future downloadVideo(
      String link,
      ) async {
    Dio dio = Dio();

    String savePath =
    await getPathFile();

    try {
      await dio.download(
        link,
        savePath,
        onReceiveProgress:
            (received, total) {
          setState(() {
            progress =
                received / total;
          });
        },
      );

      if (await File(savePath)
          .exists()) {
        await GallerySaverUtil
            .saveVideoToGallery(
          savePath,
        );

        if (context.mounted) {
          Flushbar(
            margin:
            const EdgeInsets.all(
              16,
            ),
            borderRadius:
            BorderRadius.circular(
              16,
            ),
            backgroundColor:
            const Color(
              0xff00C853,
            ),
            duration:
            const Duration(
              seconds: 2,
            ),
            icon: const Icon(
              Icons.check_circle,
              color: Colors.white,
            ),
            messageText:
            const Text(
              "Download Successful! 🎉",
              style: TextStyle(
                color:
                Colors.white,
                fontWeight:
                FontWeight
                    .bold,
              ),
            ),
          ).show(context);
        }
      }
    } catch (e) {
      if (context.mounted) {
        Flushbar(
          margin:
          const EdgeInsets.all(
            16,
          ),
          borderRadius:
          BorderRadius.circular(
            16,
          ),
          backgroundColor:
          Colors.redAccent,
          duration:
          const Duration(
            seconds: 3,
          ),
          icon: const Icon(
            Icons.error,
            color: Colors.white,
          ),
          messageText: Text(
            "Download Failed: $e",
            style:
            const TextStyle(
              color:
              Colors.white,
              fontWeight:
              FontWeight.bold,
            ),
          ),
        ).show(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          isDownloading =
          false;
        });
      }
    }
  }
}

/// ================= GRID PAINTER =================

class _GridPainter
    extends CustomPainter {
  final Color lineColor;

  _GridPainter({
    required this.lineColor,
  });

  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = .7;

    const gap = 38.0;

    for (double x = 0;
    x < size.width;
    x += gap) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (double y = 0;
    y < size.height;
    y += gap) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
      covariant CustomPainter
      oldDelegate,
      ) {
    return false;
  }
}