/// ================= IMPORTS =================

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:another_flushbar/flushbar.dart';
import 'package:dio/dio.dart';
import 'package:download_video/helpers/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../helpers/ad_helper.dart';
import '../helpers/history_util.dart';
import 'history_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController controller = TextEditingController();

  List<dynamic> medias = [];

  bool isEnable = false;
  bool isDownloading = false;
  bool isLoading = false;

  double progress = 0.0;

  String title = "";
  String imageLink = "";
  String textLoading = "Loading...";
  String link = "";

  List<String> listKeys = [];
  List<String> listYoutubeKeys = [];

  /// ================= INIT =================

  @override
  void initState() {
    super.initState();

    listKeys = Config.listKeysRemotes;
    listYoutubeKeys = Config.listKeysYoutube;

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _showRatingDialog();
      }
    });

  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  /// ================= RATING =================

  Future<void> _showRatingDialog() async {
    if (!mounted) return;

    final prefs =
        await SharedPreferences.getInstance();

    /// Nếu đã rate 4-5 sao rồi thì không hiện nữa
    final hasRated =
        prefs.getBool("has_rated") ?? false;

    if (hasRated) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CustomRatingDialog(),
    );
  }

  /// ================= HELPERS =================

  Future<String> getLink(String text) async {
    final exp = RegExp(
      r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+',
    );

    final matches = exp.allMatches(text);

    String result = "";

    if (text.contains("http://xhslink.com")) {
      for (var match in matches) {
        result = text.substring(match.start, match.end);
      }
    } else {
      result = text;
    }

    return result;
  }

  String? extractYoutubeId(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:shorts\/|watch\?v=)|youtu\.be\/)([a-zA-Z0-9_-]{11})',
    );

    final match = regExp.firstMatch(url);

    return match?.group(1);
  }

  Map<String, String> getHeaders() {
    final key = listKeys[Random().nextInt(listKeys.length)];

    dev.log("API key: $key");

    return {
      "Content-Type": "application/x-www-form-urlencoded",
      "x-rapidapi-host": "snap-video3.p.rapidapi.com",
      "x-rapidapi-key": key,
    };
  }

  /// ================= API =================

  Future<Map<String, dynamic>?> fetchTikTokAPI(String url) async {
    try {
      final uri = Uri.parse("https://tikwm.com/api/?url=$url");

      final response = await get(uri);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json["code"] == 0 && json["data"] != null) {
          final data = json["data"];

          if (data["play"] != null &&
              data["play"].toString().isNotEmpty) {
            return json;
          }
        }
      }
    } catch (e) {
      dev.log("TikTok API error: $e");
    }

    return null;
  }

  Future<Map<String, dynamic>?> fetchFacebookAPI(String url) async {
    try {
      final uri = Uri.parse("https://fdown.isuru.eu.org/info");

      final response = await post(
        uri,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({"url": url}),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json["status"] == "success" &&
            json["available_formats"] != null) {
          return json;
        }
      }
    } catch (e) {
      dev.log("Facebook API error: $e");
    }

    return null;
  }

  Future<Map<String, dynamic>?> fetchYoutubeAPI(String url) async {
    try {
      final id = extractYoutubeId(url) ?? "";

      final key = listYoutubeKeys[
      Random().nextInt(listYoutubeKeys.length)];

      final uri = Uri.parse(
        "https://ytstream-download-youtube-videos.p.rapidapi.com/dl?id=$id",
      );

      final response = await get(
        uri,
        headers: {
          "Content-Type": "application/json",
          "x-rapidapi-host":
          "ytstream-download-youtube-videos.p.rapidapi.com",
          "x-rapidapi-key": key,
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json["status"] == "OK") {
          return json;
        }
      }
    } catch (e) {
      dev.log("Youtube API error: $e");
    }

    return null;
  }

  Future<Map<String, dynamic>> postAPI([Object? body]) async {
    const int maxRetries = 10;

    int attempt = 0;

    while (attempt < maxRetries) {
      try {
        final uri = Uri.parse(
          "https://snap-video3.p.rapidapi.com/download",
        );

        final response = await post(
          uri,
          headers: getHeaders(),
          body: body,
        );

        final json = jsonDecode(response.body);

        if (response.statusCode == 200 && json != null) {
          return json;
        } else {
          throw Exception("Invalid response");
        }
      } catch (e) {
        attempt++;

        dev.log("Retry $attempt/$maxRetries - Error: $e");

        if (attempt >= maxRetries) {
          throw Exception(
            "API failed after $maxRetries attempts",
          );
        }

        await Future.delayed(
          const Duration(milliseconds: 500),
        );
      }
    }

    throw Exception("Unexpected error");
  }

  /// ================= CLIPBOARD =================

  Future<void> _getClipboardText() async {
    final data = await Clipboard.getData(
      Clipboard.kTextPlain,
    );

    link = await getLink(data?.text ?? "");

    if (!mounted) return;

    setState(() {
      controller.text = link;
      isEnable = false;
      medias = [];
    });
  }

  /// ================= GET DATA =================

  Future<void> getData() async {
    if (link.isEmpty) {
      _showError("Please paste a valid link");
      return;
    }

    try {
      /// ================= TIKTOK =================

      if (link.contains("tiktok.com")) {
        setState(() {
          textLoading = "Tiktok...";
          isLoading = true;
        });

        final tiktokJson = await fetchTikTokAPI(link);

        if (tiktokJson != null) {
          final data = tiktokJson["data"];

          final videoUrl = data["play"];
          final cover = data["cover"];
          final desc = data["title"] ?? "TikTok Video";

          if (videoUrl != null &&
              videoUrl.toString().isNotEmpty) {
            final mediasTikTok = [
              {
                "url": videoUrl,
                "quality": "hd",
                "extension": "mp4",
              },
            ];

            if (!mounted) return;

            setState(() {
              title = desc;
              imageLink = cover ?? "";
              medias = mediasTikTok;
              isEnable = true;
              isLoading = false;
            });

            await HistoryUtil.addHistory({
              "title": title,
              "thumbnail": imageLink,
              "medias": mediasTikTok,
            });

            return;
          }
        }
      }

      /// ================= FACEBOOK =================

      if (link.contains("facebook.com") ||
          link.contains("fb.watch")) {
        setState(() {
          textLoading = "Facebook...";
          isLoading = true;
        });

        final fbJson = await fetchFacebookAPI(link);

        if (fbJson != null) {
          final info = fbJson["video_info"];

          final formats =
          fbJson["available_formats"] as List;

          formats.sort((a, b) {
            final qa = int.tryParse(
              a["quality"]
                  .toString()
                  .replaceAll("p", ""),
            ) ??
                0;

            final qb = int.tryParse(
              b["quality"]
                  .toString()
                  .replaceAll("p", ""),
            ) ??
                0;

            return qb.compareTo(qa);
          });

          final best = formats.first;

          final mediasFB = [
            {
              "url": best["url"],
              "quality": best["quality"],
              "extension": "mp4",
            },
          ];

          if (!mounted) return;

          setState(() {
            title = info["title"] ?? "Facebook Video";
            imageLink = info["thumbnail"] ?? "";
            medias = mediasFB;
            isEnable = true;
            isLoading = false;
          });

          await HistoryUtil.addHistory({
            "title": title,
            "thumbnail": imageLink,
            "medias": mediasFB,
          });

          return;
        }
      }

      /// ================= YOUTUBE =================

      if (link.contains("youtube") ||
          link.contains("youtu")) {
        if (Config.checkYouTube == true) {
          _showError("Cannot get Youtube video !");
          return;
        }

        setState(() {
          textLoading = "Youtube...";
          isLoading = true;
        });

        final youtubeJson =
        await fetchYoutubeAPI(link);

        if (youtubeJson != null) {
          final thumbnail =
          youtubeJson["thumbnail"] as List<dynamic>;

          String cover = "";

          if (thumbnail.isNotEmpty) {
            cover = thumbnail.last["url"];
          }

          final desc =
              youtubeJson["title"] ?? "Youtube Video";

          final adaptiveFormats =
          youtubeJson["adaptiveFormats"]
          as List<dynamic>;

          final mp4Videos =
          adaptiveFormats.where((item) {
            final mimeType =
                item["mimeType"] ?? "";

            return mimeType.contains("video/mp4");
          }).toList();

          String videoUrl = "";

          if (mp4Videos.isNotEmpty) {
            videoUrl = mp4Videos.first["url"];
          }

          if (videoUrl.isNotEmpty) {
            final mediasYoutube = [
              {
                "url": videoUrl,
                "quality": "hd",
                "extension": "mp4",
              },
            ];

            if (!mounted) return;

            setState(() {
              title = desc;
              imageLink = cover;
              medias = mediasYoutube;
              isEnable = true;
              isLoading = false;
            });

            await HistoryUtil.addHistory({
              "title": title,
              "thumbnail": imageLink,
              "medias": mediasYoutube,
            });

            return;
          }
        }
      }

      /// ================= FALLBACK =================

      setState(() {
        textLoading = "Loading...";
        isLoading = true;
      });

      final jsons = await postAPI({
        "url": link,
      });

      if (jsons.isEmpty || jsons["medias"] == null) {
        throw Exception("Invalid response");
      }

      final mediasRaw = jsons["medias"] as List;

      final filtered = mediasRaw.where((e) {
        return e["extension"] == "mp4" &&
            (e["quality"] == "hd" ||
                e["quality"] == "720p");
      }).toList();

      if (!mounted) return;

      setState(() {
        title = jsons["title"] ?? "No title";
        imageLink = jsons["thumbnail"] ?? "";
        medias = filtered;
        isEnable = true;
        isLoading = false;
      });

      if (filtered.isEmpty) {
        _showError("No HD video found!");
        return;
      }

      await HistoryUtil.addHistory({
        "title": title,
        "thumbnail": imageLink,
        "medias": filtered,
      });
    } catch (e) {
      dev.log("ERROR: $e");

      if (!mounted) return;

      setState(() {
        isLoading = false;
        isEnable = false;
      });

      _showError("Cannot get video. Try again!");
    }
  }

  /// ================= DOWNLOAD =================

  Future<void> downloadVideo(String url) async {
    setState(() {
      isDownloading = true;
      progress = 0;
    });

    final dio = Dio();

    final path =
        "/storage/emulated/0/Download/${DateTime.now().millisecondsSinceEpoch}.mp4";

    try {
      await dio.download(
        url,
        path,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            if (!mounted) return;

            setState(() {
              progress = received / total;
            });
          }
        },
      );

      await GallerySaverUtil.saveVideoToGallery(path);

      if (!mounted) return;

      _showRatingDialog();

      Flushbar(
        margin: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(16),
        backgroundColor: const Color(0xff00C853),
        duration: const Duration(seconds: 2),
        icon: const Icon(
          Icons.check_circle,
          color: Colors.white,
        ),
        messageText: const Text(
          "Downloaded Successfully 🎉",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ).show(context);
    } catch (_) {
      if (!mounted) return;

      Flushbar(
        margin: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(16),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 2),
        icon: const Icon(
          Icons.error,
          color: Colors.white,
        ),
        messageText: const Text(
          "Download Failed ❌",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ).show(context);
    }

    if (!mounted) return;

    setState(() {
      isDownloading = false;
    });
  }

  /// ================= ERROR =================

  void _showError(String msg) {
    Flushbar(
      margin: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      backgroundGradient: const LinearGradient(
        colors: [
          Colors.redAccent,
          Colors.deepOrange,
        ],
      ),
      duration: const Duration(seconds: 2),
      icon: const Icon(
        Icons.error,
        color: Colors.white,
      ),
      messageText: Text(
        msg,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    ).show(context);
  }

  /// ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F8FC),
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Stack(
          children: [
            _bg(),

            Positioned(
              top: -120,
              right: -90,
              child: _glow(
                size: 320,
                color: const Color(0xffB8F5D3)
                    .withOpacity(.55),
              ),
            ),

            Positioned(
              bottom: -140,
              left: -100,
              child: _glow(
                size: 340,
                color: const Color(0xffD9E8FF)
                    .withOpacity(.55),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  _header(),
                  _search(),
                  _mainButton(),

                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(
                        milliseconds: 400,
                      ),
                      child: isEnable
                          ? _preview()
                          : _emptyWithAds(),
                    ),
                  ),
                ],
              ),
            ),

            if (isLoading)
              _loadingOverlay(textLoading),

            if (isDownloading)
              _buildLoading(),
          ],
        ),
      ),
    );
  }


  /// ================= UI =================

  Widget _bg() => Stack(
    children: [
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xffFFFFFF),
              Color(0xffF8FAFD),
              Color(0xffEEF3F9),
            ],
          ),
        ),
      ),

      Positioned.fill(
        child: CustomPaint(
          painter: _GridPainter(),
        ),
      ),

      Positioned.fill(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 24,
            sigmaY: 24,
          ),
          child: Container(
            color: Colors.white.withOpacity(.08),
          ),
        ),
      ),
    ],
  );

  Widget _header() => Padding(
    padding:
    const EdgeInsets.fromLTRB(20, 18, 20, 10),
    child: Row(
      mainAxisAlignment:
      MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) {
                return const LinearGradient(
                  colors: [
                    Color(0xff111111),
                    Color(0xff444444),
                    Color(0xff00C853),
                  ],
                ).createShader(bounds);
              },
              child: const Text(
                "Snap Video",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -.5,
                ),
              ),
            ),

            const SizedBox(height: 4),

            Text(
              "Fast • HD • No Watermark",
              style: TextStyle(
                color:
                Colors.black.withOpacity(.45),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                const HistoryPage(),
              ),
            );
          },
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius:
              BorderRadius.circular(18),
              color:
              Colors.white.withOpacity(.75),
              border: Border.all(
                color:
                Colors.white,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withOpacity(.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.history_rounded,
              color: Color(0xff111111),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _search() => Container(
    margin:
    const EdgeInsets.symmetric(horizontal: 20),
    padding:
    const EdgeInsets.symmetric(horizontal: 16),
    height: 62,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      color: Colors.white.withOpacity(.75),
      border: Border.all(
        color: Colors.white,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.05),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius:
            BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [
                Color(0xff00E676),
                Color(0xff00C853),
              ],
            ),
          ),
          child: const Icon(
            Icons.link_rounded,
            color: Colors.white,
          ),
        ),

        const SizedBox(width: 14),

        Expanded(
          child: TextField(
            controller: controller,
            readOnly: true,
            keyboardType: TextInputType.none,
            enableInteractiveSelection: false,
            showCursor: false,
            focusNode: FocusNode(
              canRequestFocus: false,
            ),
            style: const TextStyle(
              color: Color(0xff111111),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText:
              "Paste video link here...",
              hintStyle: TextStyle(
                color:
                Colors.black.withOpacity(.35),
              ),
              border: InputBorder.none,
            ),
          ),
        ),

        GestureDetector(
          onTap: _getClipboardText,
          child: Container(
            padding:
            const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              borderRadius:
              BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [
                  Color(0xff111111),
                  Color(0xff2C2C2C),
                ],
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.content_paste_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                SizedBox(width: 6),
                Text(
                  "Paste",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _mainButton() => Padding(
    padding: const EdgeInsets.all(20),
    child: _button(
      text: "Get Video",
      icon: Icons.download_rounded,
      onTap: () async {
        if (link.isEmpty) return;

        final prefs =
            await SharedPreferences.getInstance();

        /// Nếu đã rate 4-5 sao rồi thì không hiện nữa
        final hasRated =
            prefs.getBool("has_rated") ?? false;

        if (hasRated) {
          AdHelper.showInterstitial(() {
            getData();
          });
        } else {
          getData();
        }
      },
    ),
  );

  Widget _preview() => Padding(
    padding:
    const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius:
            BorderRadius.circular(24),
            color:
            Colors.white.withOpacity(.04),
            border: Border.all(
              color:
              Colors.white.withOpacity(.06),
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius:
                BorderRadius.circular(16),
                child: Image.network(
                  imageLink,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow:
                  TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight:
                    FontWeight.w700,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        Expanded(
          child: _buildVideoPreview(),
        ),

        const SizedBox(height: 12),

        ...medias.map(
              (m) => Padding(
            padding:
            const EdgeInsets.only(bottom: 12),
            child: _button(
              text: "Download HD",
              icon: Icons.download,
              onTap: () async {
                setState(() {
                  isLoading = true;
                });

                final prefs =
                    await SharedPreferences.getInstance();

                /// Nếu đã rate 4-5 sao rồi thì không hiện nữa
                final hasRated =
                    prefs.getBool("has_rated") ?? false;

                if (hasRated) {
                  AdHelper.showInterstitial(() {
                    setState(() {
                      isLoading = false;
                    });

                    downloadVideo(m["url"]);
                  });
                } else {
                  downloadVideo(m["url"]);
                }
              },
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildVideoPreview() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: 1 / 1,
            child: Image.network(
              imageLink,
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(.15),
                    Colors.black.withOpacity(.55),
                  ],
                ),
              ),
            ),
          ),

          TweenAnimationBuilder<double>(
            tween: Tween(begin: .92, end: 1.08),
            duration:
            const Duration(milliseconds: 1200),
            curve: Curves.easeInOut,
            builder: (_, scale, child) {
              return Transform.scale(
                scale: scale,
                child: child,
              );
            },
            onEnd: () {
              if (mounted) {
                setState(() {});
              }
            },
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                Colors.white.withOpacity(.10),
                border: Border.all(
                  color:
                  Colors.white.withOpacity(.15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff00E676)
                        .withOpacity(.30),
                    blurRadius: 40,
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyWithAds() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 28,
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            const SizedBox(height: 24),

            ShaderMask(
              shaderCallback: (bounds) {
                return const LinearGradient(
                  colors: [
                    const Color(0xff111111),
                    const Color(0xff5A5A5A),
                    const Color(0xff00C853),
                  ],
                ).createShader(bounds);
              },
              child: const Text(
                "Paste Link to Download",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -.5,
                  height: 1.1,
                ),
              ),
            ),

            const SizedBox(height: 16),

            Text(
              "Download videos instantly in ultra HD quality with blazing fast speed and zero watermark.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                Colors.black.withOpacity(.60),
                fontSize: 14,
                height: 1.7,
              ),
            ),

            const SizedBox(height: 30),

            // GestureDetector(
            //   onTap: _getClipboardText,
            //   child: Container(
            //     padding:
            //     const EdgeInsets.symmetric(
            //       horizontal: 28,
            //       vertical: 18,
            //     ),
            //     decoration: BoxDecoration(
            //       borderRadius:
            //       BorderRadius.circular(24),
            //       gradient: const LinearGradient(
            //         colors: [
            //           Color(0xff00E676),
            //           Color(0xff00C853),
            //         ],
            //       ),
            //       boxShadow: [
            //         BoxShadow(
            //           color: const Color(0xff00E676)
            //               .withOpacity(.35),
            //           blurRadius: 30,
            //         ),
            //       ],
            //     ),
            //     child: const Row(
            //       mainAxisSize: MainAxisSize.min,
            //       children: [
            //         Icon(
            //           Icons.content_paste_rounded,
            //           color: Colors.white,
            //         ),
            //         SizedBox(width: 10),
            //         Text(
            //           "Paste & Download",
            //           style: TextStyle(
            //             color: Colors.white,
            //             fontWeight:
            //             FontWeight.w900,
            //             fontSize: 15,
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),
            //
            // const SizedBox(height: 24),

            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                _feature("No Watermark"),
                _feature("4K HD"),
                _feature("Ultra Fast"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _feature(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.black.withOpacity(.05),
        border: Border.all(
          color: Colors.black.withOpacity(.06),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: Colors.black.withOpacity(.75),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _button({
    required String text,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [
              Color(0xff00E676),
              Color(0xff00C853),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff00E676)
                  .withOpacity(.35),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),

            const SizedBox(width: 10),

            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingOverlay(String text) {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 10,
          sigmaY: 10,
        ),
        child: Container(
          color: Colors.black.withOpacity(.45),
          child: Center(
            child: Container(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 30,
                vertical: 24,
              ),
              decoration: BoxDecoration(
                borderRadius:
                BorderRadius.circular(28),
                color:
                Colors.white.withOpacity(.05),
                border: Border.all(
                  color:
                  Colors.white.withOpacity(.08),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 42,
                    height: 42,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      color: Color(0xff00E676),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight:
                      FontWeight.w700,
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

  Widget _buildLoading() {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 12,
          sigmaY: 12,
        ),
        child: Container(
          color: Colors.black.withOpacity(.45),
          child: Center(
            child: Container(
              width: 180,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius:
                BorderRadius.circular(34),
                color:
                Colors.white.withOpacity(.05),
                border: Border.all(
                  color:
                  Colors.white.withOpacity(.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff00E676)
                        .withOpacity(.25),
                    blurRadius: 40,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 82,
                        height: 82,
                        child:
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 6,
                          backgroundColor:
                          Colors.white
                              .withOpacity(.08),
                          valueColor:
                          const AlwaysStoppedAnimation(
                            Color(0xff00E676),
                          ),
                        ),
                      ),

                      Text(
                        "${(progress * 100).toInt()}%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight:
                          FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    "Downloading...",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight:
                      FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Preparing ultra fast download",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:
                      Colors.white.withOpacity(
                        .55,
                      ),
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 18),

                  ClipRRect(
                    borderRadius:
                    BorderRadius.circular(30),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor:
                      Colors.white
                          .withOpacity(.06),
                      valueColor:
                      const AlwaysStoppedAnimation(
                        Color(0xff00E676),
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

  Widget _glow({
    required double size,
    required Color color,
  }) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
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
}

/// ================= GRID =================

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(.03)
      ..strokeWidth = .6;

    const gap = 38.0;

    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
      covariant CustomPainter oldDelegate,
      ) {
    return false;
  }
}

/// ================= GALLERY =================

class GallerySaverUtil {
  static const MethodChannel _channel =
  MethodChannel(
    "com.example.save_video/gallery",
  );

  static Future<void> saveVideoToGallery(
      String path,
      ) async {
    if (Platform.isAndroid) {
      await _channel.invokeMethod(
        "saveVideoToGallery",
        {"path": path},
      );
    }
  }
}

class CustomRatingDialog extends StatefulWidget {
  const CustomRatingDialog({super.key});

  @override
  State<CustomRatingDialog> createState() =>
      _CustomRatingDialogState();
}

class _CustomRatingDialogState
    extends State<CustomRatingDialog>
    with TickerProviderStateMixin {

  int _selectedRating = 5;

  final InAppReview _inAppReview =
      InAppReview.instance;

  late final AnimationController
  _pulseController;

  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1600,
      ),
    )..repeat(reverse: true);

    _pulse = Tween<double>(
      begin: .96,
      end: 1.04,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    Navigator.pop(context);

    if (_selectedRating >= 4) {
      try {
        final prefs =
        await SharedPreferences.getInstance();

        /// Đánh dấu đã rate hài lòng
        await prefs.setBool(
          "has_rated",
          true,
        );

        if (await _inAppReview.isAvailable()) {
          await _inAppReview.requestReview();
        } else {
          await _inAppReview.openStoreListing();
        }
      } catch (e) {
        await launchUrl(
          Uri.parse(
            "https://play.google.com/store/apps/details?id=com.ndp.snapvideo",
          ),
          mode: LaunchMode.externalApplication,
        );
      }

      if (!mounted) return;

      _showSnack(
        "Thanks for supporting Snap Video ❤️",
      );
    } else {
      if (!mounted) return;

      _showSnack(
        "Thanks! We'll improve your experience 🚀",
      );
    }
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
        const Color(0xff111111),
        shape: RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(18),
        ),
        content: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:
      const EdgeInsets.symmetric(
        horizontal: 22,
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: .9, end: 1),
        duration: const Duration(
          milliseconds: 450,
        ),
        curve: Curves.easeOutBack,
        builder: (_, scale, child) {
          return Transform.scale(
            scale: scale,
            child: child,
          );
        },
        child: ClipRRect(
          borderRadius:
          BorderRadius.circular(36),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 30,
              sigmaY: 30,
            ),
            child: Container(
              padding:
              const EdgeInsets.all(26),
              decoration: BoxDecoration(
                borderRadius:
                BorderRadius.circular(36),

                color:
                Colors.white.withOpacity(
                  .78,
                ),

                border: Border.all(
                  color:
                  Colors.white,
                ),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withOpacity(.06),
                    blurRadius: 40,
                    offset:
                    const Offset(0, 14),
                  ),

                  BoxShadow(
                    color: const Color(
                      0xff00E676,
                    ).withOpacity(.18),
                    blurRadius: 60,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize:
                MainAxisSize.min,
                children: [

                  /// ICON
                  AnimatedBuilder(
                    animation: _pulse,
                    builder: (_, child) {
                      return Transform.scale(
                        scale: _pulse.value,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration:
                      BoxDecoration(
                        shape:
                        BoxShape.circle,
                        gradient:
                        const LinearGradient(
                          colors: [
                            Color(0xff00E676),
                            Color(0xff00C853),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xff00E676,
                            ).withOpacity(.35),
                            blurRadius: 35,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.download_rounded,
                        color: Colors.white,
                        size: 46,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// TITLE
                  ShaderMask(
                    shaderCallback: (rect) {
                      return const LinearGradient(
                        colors: [
                          Color(0xff111111),
                          Color(0xff4B4B4B),
                          Color(0xff00C853),
                        ],
                      ).createShader(rect);
                    },
                    child: const Text(
                      "Enjoying Snap Video?",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight:
                        FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -.6,
                        height: 1.1,
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  /// DESC
                  Text(
                    "Your feedback helps us improve download speed, quality and overall experience.",
                    textAlign:
                    TextAlign.center,
                    style: TextStyle(
                      color: Colors.black
                          .withOpacity(.55),
                      fontSize: 14,
                      height: 1.6,
                      fontWeight:
                      FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 28),

                  /// STARS
                  Wrap(
                    alignment:
                    WrapAlignment.center,
                    spacing: 10,
                    children: List.generate(
                      5,
                          (index) {
                        final active =
                            index <
                                _selectedRating;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedRating =
                                  index + 1;
                            });
                          },
                          child:
                          AnimatedContainer(
                            duration:
                            const Duration(
                              milliseconds:
                              220,
                            ),
                            curve:
                            Curves.easeOut,
                            width:
                            active
                                ? 62
                                : 56,
                            height:
                            active
                                ? 62
                                : 56,
                            decoration:
                            BoxDecoration(
                              shape:
                              BoxShape.circle,
                              color: active
                                  ? const Color(
                                0xff00E676,
                              ).withOpacity(
                                .14,
                              )
                                  : Colors.white,
                              border:
                              Border.all(
                                color: active
                                    ? const Color(
                                  0xff00E676,
                                )
                                    : const Color(
                                  0xffE9EEF5,
                                ),
                              ),
                              boxShadow:
                              [
                                BoxShadow(
                                  color: Colors
                                      .black
                                      .withOpacity(
                                    .04,
                                  ),
                                  blurRadius:
                                  16,
                                  offset:
                                  const Offset(
                                    0,
                                    6,
                                  ),
                                ),
                              ],
                            ),
                            child: Icon(
                              active
                                  ? Icons.star_rounded
                                  : Icons
                                  .star_border_rounded,
                              color: active
                                  ? const Color(
                                0xff00C853,
                              )
                                  : Colors.black
                                  .withOpacity(
                                .22,
                              ),
                              size: 34,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  /// BUTTON
                  GestureDetector(
                    onTap: _submitRating,
                    child: Container(
                      height: 60,
                      alignment:
                      Alignment.center,
                      decoration:
                      BoxDecoration(
                        borderRadius:
                        BorderRadius.circular(
                          24,
                        ),
                        gradient:
                        const LinearGradient(
                          colors: [
                            Color(0xff111111),
                            Color(0xff2C2C2C),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withOpacity(.14),
                            blurRadius: 28,
                            offset:
                            const Offset(
                              0,
                              10,
                            ),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                        children: [
                          const Icon(
                            Icons.favorite_rounded,
                            color: Colors.white,
                            size: 22,
                          ),

                          const SizedBox(
                              width: 10),

                          Text(
                            _selectedRating >= 4
                                ? "Rate on Play Store"
                                : "Send Feedback",
                            style:
                            const TextStyle(
                              color:
                              Colors.white,
                              fontWeight:
                              FontWeight
                                  .w900,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}