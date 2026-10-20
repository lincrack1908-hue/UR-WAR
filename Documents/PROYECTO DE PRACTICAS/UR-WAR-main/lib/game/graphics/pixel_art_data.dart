import 'package:flutter/material.dart';

/// Define un sprite de pixel art de alta precisión basado en una matriz de caracteres.
class PixelSpriteData {
  final String visualId;
  final double phase;
  final bool moving, attacking, facingAway;
  final int width;
  final int height;
  final List<String> matrix;
  final Map<String, Color> palette;

  const PixelSpriteData({
    this.visualId = '',
    this.phase = 0,
    this.moving = false,
    this.attacking = false,
    this.facingAway = false,
    required this.width,
    required this.height,
    required this.matrix,
    required this.palette,
  });
}

/// Contiene las matrices de Pixel Art detalladas para personajes, enemigos,
/// edificios de la aldea y elementos del mapa.
class PixelArtLibrary {
  // ==========================================
  // PALETAS COMUNES
  // ==========================================
  static const Color cTrans = Colors.transparent;
  static const Color cBlack = Color(0xFF141419);
  static const Color cSkin = Color(0xFFFFCC99);
  static const Color cSkinShadow = Color(0xFFE5A672);

  // ==========================================
  // 1. CABALLERO / PALADÍN (KNIGHT) - 16x16
  // ==========================================
  static final PixelSpriteData knightIdle = PixelSpriteData(
    visualId: 'knightIdle',
    width: 16,
    height: 16,
    palette: {
      '.': cTrans,
      '#': cBlack,
      'r': const Color(0xFFD90429), // Pluma roja del yelmo
      's': const Color(0xFFC0C0D0), // Metal plateado
      'S': const Color(0xFFE8E8F0), // Brillo metal
      'd': const Color(0xFF707088), // Sombra metal
      'g': const Color(0xFFFFD166), // Oro adorno
      'b': const Color(0xFF1D3557), // Capa azul
      'B': const Color(0xFF457B9D), // Capa azul brillante
      'w': Colors.white,
      'e': const Color(0xFF101015), // Ojos en la visera
    },
    matrix: [
      '....###r###.....',
      '...#rrr#rrr#....',
      '..#ssSssssss#...',
      '..#s#e#ss#e#s#..',
      '..#ssSssssss#...',
      '..#ggddddddgg#..',
      '.#b#ssssssss#b#.',
      '#Bb#sggwwggs#bB#',
      '#Bb#ssswwsss#bB#',
      '.#b#ssssssss#b#.',
      '..#g########g#..',
      '...#ssssssss#...',
      '...#sdd##dds#...',
      '...#sdd##dds#...',
      '..#ssdd##ddss#..',
      '..############..',
    ],
  );

  static final PixelSpriteData knightAttack = PixelSpriteData(
    visualId: 'knightAttack',
    width: 18,
    height: 16,
    palette: {
      '.': cTrans,
      '#': cBlack,
      'r': const Color(0xFFEF233C),
      's': const Color(0xFFC0C0D0),
      'S': const Color(0xFFFFFFFF),
      'd': const Color(0xFF707088),
      'g': const Color(0xFFFFD166),
      'b': const Color(0xFF1D3557),
      'w': Colors.white,
      'e': const Color(0xFF101015),
    },
    matrix: [
      '....###r###...SS..',
      '...#rrr#rrr#..SS#.',
      '..#ssSssssss#.sS#.',
      '..#s#e#ss#e#s#sS#.',
      '..#ssSssssss#ssS#.',
      '..#ggddddddgg#sS#.',
      '.#b#ssssssss#bsS#.',
      '#Bb#sggwwggs#gg##.',
      '#Bb#ssswwsss#g#...',
      '.#b#ssssssss#b#...',
      '..#g########g#....',
      '...#ssssssss#.....',
      '...#sdd##dds#.....',
      '..#ssdd##dds#.....',
      '.#sssdd##ddss#....',
      '.#####..######....',
    ],
  );

  // ==========================================
  // 2. ARQUERA / CAZADORA (RANGER) - 16x16
  // ==========================================
  static final PixelSpriteData rangerIdle = PixelSpriteData(
    visualId: 'rangerIdle',
    width: 16,
    height: 16,
    palette: {
      '.': cTrans,
      '#': cBlack,
      'h': const Color(0xFF2B9348), // Capucha verde
      'H': const Color(0xFF55A630), // Capucha clara
      'f': const Color(0xFFFFD166), // Pelo rubio
      'k': cSkin, // Piel
      'K': cSkinShadow,
      'e': const Color(0xFF007200), // Ojos verdes
      't': const Color(0xFF6B705C), // Túnica cuero verde/marrón
      'b': const Color(0xFF7F4F24), // Cinturón / Carcaj
      'B': const Color(0xFF936639), // Cuero claro
      'w': const Color(0xFFDDB892), // Botas
    },
    matrix: [
      '....########....',
      '...#HHHHHHHH#...',
      '..#HhhhhhhhhH#..',
      '..#H#k#fff#k#H#.',
      '..#Hk#e#f#e#kH#.',
      '..#HkkkkkkkkH#..',
      '..#H##ffff##H#..',
      '...#b#tttt#B#...',
      '..#Bb#tttt#bB#..',
      '..#bB#bbbb#Bb#..',
      '...#K#tttt#K#...',
      '...#b#ffff#b#...',
      '...#B#b##b#B#...',
      '...#B#b##b#B#...',
      '..#wwb####bww#..',
      '..####....####..',
    ],
  );

  static final PixelSpriteData rangerAttack = PixelSpriteData(
    visualId: 'rangerAttack',
    width: 18,
    height: 16,
    palette: {
      '.': cTrans,
      '#': cBlack,
      'h': const Color(0xFF2B9348),
      'H': const Color(0xFF55A630),
      'f': const Color(0xFFFFD166),
      'k': cSkin,
      'e': const Color(0xFF007200),
      't': const Color(0xFF6B705C),
      'b': const Color(0xFF7F4F24),
      'B': const Color(0xFF936639),
      'w': const Color(0xFFDDB892),
      'a': const Color(0xFFB08968), // Arco de madera
      's': Colors.white, // Cuerda
    },
    matrix: [
      '....########...a#.',
      '...#HHHHHHHH#..as.',
      '..#HhhhhhhhhH#.as.',
      '..#H#k#fff#k#H#as.',
      '..#Hk#e#f#e#kHas.',
      '..#HkkkkkkkkH#as.',
      '..#H##ffff##Has.',
      '...#b#tttt#B#has.',
      '..#Bb#tttt#bBas.',
      '..#bB#bbbb#Bbas.',
      '...#K#tttt#K#as.',
      '...#b#ffff#b#as.',
      '...#B#b##b#B#as.',
      '..#ww#b##b#ww#a#.',
      '..####....####....',
      '..................',
    ],
  );

  // ==========================================
  // 3. MAGO ARCANO (MAGE) - 16x16
  // ==========================================
  static final PixelSpriteData mageIdle = PixelSpriteData(
    visualId: 'mageIdle',
    width: 16,
    height: 16,
    palette: {
      '.': cTrans,
      '#': cBlack,
      'p': const Color(0xFF5A189A), // Túnica púrpura
      'P': const Color(0xFF7B2CBF), // Púrpura brillante
      'l': const Color(0xFF9D4EDD), // Resplandor
      'g': const Color(0xFFFFD166), // Estrella dorada
      'k': cSkin,
      'b': const Color(0xFFE0AAFF), // Barba canosa/mágica
      'e': const Color(0xFF00F5D4), // Ojos de maná brillante
      'w': const Color(0xFF3C096C), // Capucha fondo
      's': const Color(0xFF7F4F24), // Báculo
      'c': const Color(0xFF00BBF9), // Gema báculo
    },
    matrix: [
      '.....######.....',
      '....#PPggPP#....',
      '...#PppppppP#...',
      '..#PppPggPppP#..',
      '..#P#k#PP#k#P#..',
      '..#Pk#e##e#kP#..',
      '..#PkkbbbbkkP#c#',
      '...#PbbbbbbP#cc#',
      '..#PPbbbbbbPP#s#',
      '.#PllppppppllP#s',
      '.#PllppppppllP#s',
      '.#PPppppppppPP#s',
      '.#PPppppppppPP#s',
      '.#PppppppppppP#s',
      '#PPppppppppppPP#',
      '################',
    ],
  );

  // ==========================================
  // 4. CLÉRIGA / GUARDIANA (VALKYRIE) - 16x16
  // ==========================================
  static final PixelSpriteData clericIdle = PixelSpriteData(
    visualId: 'clericIdle',
    width: 16,
    height: 16,
    palette: {
      '.': cTrans,
      '#': cBlack,
      'g': const Color(0xFFFFB703), // Tiara/aureola dorada
      'G': const Color(0xFFFFE6A7),
      'h': const Color(0xFF8338EC), // Pelo violeta
      'k': cSkin,
      'e': const Color(0xFF3A86FF), // Ojos zafiro
      'w': Colors.white, // Coraza blanca celestial
      'W': const Color(0xFFD6E2E9),
      'b': const Color(0xFF3A86FF), // Ribetes celestes
      'm': const Color(0xFF4A4E69), // Martillo sagrado
      'M': const Color(0xFFFFD166), // Runas del martillo
    },
    matrix: [
      '....###GG###....',
      '...#ggGGGGgg#...',
      '..#gGghhhhgGg#..',
      '..#g#k#hh#k#g#..',
      '..#hk#e##e#kh#..',
      '..#hkkkkkkkkh#..',
      '..#hhkkkkkkhh#..',
      '...#W#wwww#W#...',
      '..#WW#wb#w#WW#..',
      '.#gWW#bbbb#WWg#.',
      '..#WW#wwww#WW#..',
      '...#W#bbbb#W#...',
      '..#bW#wwww#Wb#..',
      '..#W##W##W##W#..',
      '..#WW#W##W#WW#..',
      '..####.##.####..',
    ],
  );

  // ==========================================
  // ENEMIGO 1: GOBLIN SAQUEADOR - 16x16
  // ==========================================
  static final PixelSpriteData goblin = PixelSpriteData(
    visualId: 'goblin',
    width: 16,
    height: 16,
    palette: {
      '.': cTrans,
      '#': cBlack,
      'g': const Color(0xFF55A630), // Piel verde
      'G': const Color(0xFF80B918), // Piel verde claro
      'd': const Color(0xFF2B9348), // Sombra piel
      'e': const Color(0xFFFF0054), // Ojos rojos
      't': const Color(0xFFF72585), // Oreja interior
      'b': const Color(0xFF6B4226), // Ropas cuero marrón
      'k': const Color(0xFFD4A373), // Daga mango
      'm': const Color(0xFFC0C0C0), // Daga metal
    },
    matrix: [
      '#t#..........#t#',
      '#tt##......##tt#',
      '.#tgG######Ggt#.',
      '..#gGGGGGGGGg#..',
      '..#g#e#GG#e#g#..',
      '..#gGG####GGg#..',
      '...#g#GGGG#g#...',
      '....#dddddd#....',
      '..#b#dddddd#b#..',
      '..#bb#bbbb#bb#..',
      '..#bb#bbbb#bb#m#',
      '...#b######b#mm#',
      '...#g######g#k#.',
      '...#g#....#g#...',
      '..#gg#....#gg#..',
      '..####....####..',
    ],
  );

  // ==========================================
  // ENEMIGO 2: ORCO BERSERKER - 18x18
  // ==========================================
  static final PixelSpriteData orc = PixelSpriteData(
    visualId: 'orc',
    width: 18,
    height: 18,
    palette: {
      '.': cTrans,
      '#': cBlack,
      'g': const Color(0xFF386641), // Verde orco oscuro
      'G': const Color(0xFF6A994E), // Verde orco músculo
      'r': const Color(0xFFBC4749), // Pintura de guerra roja
      'h': const Color(0xFF4A4E69), // Casco con pinchos
      'e': const Color(0xFFFFD166), // Ojos amarillos furia
      'w': Colors.white, // Colmillos
      'c': const Color(0xFF7F4F24), // Armadura cuero
      'C': const Color(0xFF43281C), // Cuero oscuro
      'm': const Color(0xFF222222), // Garrote pesado
      'p': const Color(0xFF999999), // Pinchos garrote
    },
    matrix: [
      '....#h##h##h#.....',
      '..#hh########hh#..',
      '..#h#GGrrGG#h#....',
      '..#G#e#rr#e#G#....',
      '..#GGG#ww#GGG#....',
      '..#gGwwwwwwGg#....',
      '..#gggggggggg#....',
      '.#G#cccGGccc#G#...',
      '#GG#cCCCCCCc#GG#..',
      '#GG#cCCCCCCc#GG#p#',
      '#GG#cccccccc#GG#m#',
      '.#G#CCCCCCCC#G#pm#',
      '..#G########G#mmm#',
      '..#gGG####GGg#mmm#',
      '..#gGG####GGg#pm#.',
      '..#ggg####ggg##...',
      '.#gggg####gggg#...',
      '.#####....#####...',
    ],
  );

  // ==========================================
  // ENEMIGO NUEVO: TROLL DE LAS CAVERNAS - 18x18
  // (misma silueta que el orco, con piel azul grisácea)
  // ==========================================
  static final PixelSpriteData troll = PixelSpriteData(
    visualId: 'troll',
    width: orc.width,
    height: orc.height,
    palette: {
      ...orc.palette,
      'g': const Color(0xFF3B4F63), // Piel azul oscura
      'G': const Color(0xFF6C8EA4), // Piel azul clara
      'r': const Color(0xFF8E7CC3), // Marcas moradas
      'e': const Color(0xFFFF6B35), // Ojos naranjas
    },
    matrix: orc.matrix,
  );

  // ==========================================
  // ENEMIGO 3: ESQUELETO TIRADOR - 16x16
  // ==========================================
  static final PixelSpriteData skeleton = PixelSpriteData(
    visualId: 'skeleton',
    width: 16,
    height: 16,
    palette: {
      '.': cTrans,
      '#': cBlack,
      'b': const Color(0xFFE8E8E8), // Hueso blanco
      'B': const Color(0xFFF5F5F5), // Hueso brillo
      's': const Color(0xFFAAAAAA), // Hueso sombra
      'e': const Color(0xFFFF0054), // Ojo espectral rojo
      'c': const Color(0xFF4A4E69), // Harapos / Capa
      'w': const Color(0xFF8B5A2B), // Arco de madera
      'S': Colors.white, // Cuerda
    },
    matrix: [
      '.....######.....',
      '....#BBBBBB#....',
      '...#BBbbbbBB#...',
      '...#B#e##e#B#...',
      '...#BBbbbbBB#...',
      '....#s####s#....',
      '....#b#bb#b#....',
      '..#c#bbbbbb#c#w#',
      '.#cc##bbbb##c#w#',
      '.#c#s#b##b#s#c#s',
      '..##s#b##b#s##ws',
      '....#s####s#..ws',
      '....#b####b#..w#',
      '...#bb####bb#...',
      '...#bb####bb#...',
      '..####....####..',
    ],
  );

  // ==========================================
  // ENEMIGO 4: NIGROMANTE OSCURO - 16x16
  // ==========================================
  static final PixelSpriteData necromancer = PixelSpriteData(
    visualId: 'necromancer',
    width: 16,
    height: 16,
    palette: {
      '.': cTrans,
      '#': cBlack,
      'r': const Color(0xFF240046), // Túnica oscura
      'R': const Color(0xFF3C096C), // Púrpura sombrío
      'k': const Color(0xFFD8F3DC), // Rostro cadavérico pálido
      'e': const Color(0xFF70E000), // Ojos verde fuego vil
      'm': const Color(0xFF5A189A), // Manto
      'g': const Color(0xFF38B000), // Orbe verde vil flotante
      'G': const Color(0xFF70E000),
      's': const Color(0xFF4A4E69), // Báculo de hueso
    },
    matrix: [
      '.....######.....',
      '....#RRRRRR#....',
      '...#RrrrrrrR#...',
      '..#Rrr#kk#rrR#..',
      '..#Rr#e##e#rR#..',
      '..#Rrk#kk#krR#..',
      '..#RkkkkkkkkR#..',
      '...#R#rrrr#R#...',
      '..#RR#rmmr#RR#g#',
      '.#mRR#rmmr#RR#GG',
      '.#mRR#rrrr#RR#gs',
      '.#RRR#rrrr#RRR#s',
      '#RRRRrrrrrrRRRR#',
      '#RrrrrrrrrrrrrR#',
      '#RRRRRRRRRRRRRR#',
      '################',
    ],
  );

  // ==========================================
  // ENEMIGO 5: TITÁN DESTRUCTOR (BOSS) - 24x24
  // ==========================================
  static final PixelSpriteData bossTitan = PixelSpriteData(
    visualId: 'bossTitan',
    width: 24,
    height: 24,
    palette: {
      '.': cTrans,
      '#': cBlack,
      'h': const Color(0xFF6A040F), // Cuernos demoníacos
      'H': const Color(0xFF9D0208),
      'b': const Color(0xFF2B2D42), // Piel de piedra volcánica
      'B': const Color(0xFF3D405B),
      'l': const Color(0xFFFF5400), // Grietas de magma ardiente
      'L': const Color(0xFFFFB703), // Fuego volcánico interior
      'e': const Color(0xFFFFF3B0), // Ojos de fuego blanco
      'a': const Color(0xFF14213D), // Placas de hierro negro
      'x': const Color(0xFF9D0208), // Hacha sangrienta
      'X': const Color(0xFFD00000),
    },
    matrix: [
      '#h#..................#h#',
      '#Hh#................#hH#',
      '.#Hh##............##hH#.',
      '..#Hhh############hhH#..',
      '..#hhhhBBBBBBBBBBhhhh#..',
      '...#hhBbbbbbbbbBbbhh#...',
      '...#B#e##bbllobb##e#B#..',
      '...#BBb#e#bllb#e#bBB#...',
      '..#BBBbbblLLLllbbbBBB#..',
      '..#BBbbbb#llll#bbbbBB#..',
      '.#a#BBbbbbbbbbbbbbBB#a#.',
      '#aa#BBbblLllLllbbBB#aa#.',
      '#aa#aBBbbllLllbbBBa#aa#X',
      '#aa#aaBBbblllbbBBaa#aaXX',
      '.#a#aaBBBbbbbBBaa#a#xXXX',
      '..##aaBBBbbbbBBaa##.xXXX',
      '...#aaBBBbbbbBBaa#..xXX#',
      '...#aaBBBbbbbBBaa#...#X#',
      '...#aaBB#....#BBaa#...##',
      '...#aaBB#....#BBaa#.....',
      '..#aaaBB#....#BBaaa#....',
      '..#aaaBB#....#BBaaa#....',
      '.#aaaaBB#....#BBaaaa#...',
      '.########....########...',
    ],
  );

  // ==========================================
  // ENEMIGO 6: DRAGÓN DE MAGMA (MAGMA DRAGON) - 24x24
  // ==========================================
  static final PixelSpriteData magmaDragon = PixelSpriteData(
    visualId: 'magmaDragon',
    width: 24,
    height: 24,
    palette: {
      '.': cTrans,
      '#': cBlack,
      'r': const Color(0xFF6A040F), // Escama lava oscura
      'R': const Color(0xFFD00000), // Escama roja brillante
      'o': const Color(0xFFDC2F02), // Magma ardiente
      'y': const Color(0xFFFFBA08), // Fuego intenso
      'e': const Color(0xFFFFFFFF), // Ojos amarillos/blancos
      'w': const Color(0xFFE85D04), // Membrana alas
      'W': const Color(0xFF9D0208), // Sombra alas
      'h': const Color(0xFF212529), // Cuernos negros
    },
    matrix: [
      '#h#..................#h#',
      '#hh#...######.......#hh#',
      '.#hh#.#WwwwwW#.....#hh#.',
      '..#h##WwWWwwW##...#hh#..',
      '..#rr#wWrrRWw#rr##hh#...',
      '..#rR#WrrrrRR#RrR#h#....',
      '..#rR#rrrrrrrr#RrR#.....',
      '..#rR#r#e#rr#e#RrR#.....',
      '..#rRR#rroooo#RRrR#.....',
      '...#rRR#oooo#RRrR#......',
      '...#wWrr#y#rrWw#........',
      '..#WwWrrrRRrrrWwW#......',
      '.#WwWwrrrRRrrrWwWw#.....',
      '#WwWw#rrrRRrrr#WwWw#....',
      '#wWw#.#ooYYoo#.#wWw#....',
      '#Ww#..#oYYYYo#..#wW#....',
      '.##...#rrRRrr#...##.....',
      '......#rrRRrr#..........',
      '.....#rrrRRrrr#.........',
      '.....#rrR##Rrr#.........',
      '....#rrr#..#rrr#........',
      '....#rrr#..#rrr#........',
      '....#rrr#..#rrr#........',
      '....#####..#####........',
    ],
  );

  // ==========================================
  // ENEMIGO 7: LICH NIGROMANTE (LICH) - 18x18
  // ==========================================
  static final PixelSpriteData lich = PixelSpriteData(
    visualId: 'lich',
    width: 18,
    height: 18,
    palette: {
      '.': cTrans,
      '#': cBlack,
      'k': const Color(0xFFE9ECEF), // Hueso/Cráneo
      'K': const Color(0xFFADB5BD), // Sombra hueso
      'r': const Color(0xFF10002B), // Túnica vacío
      'R': const Color(0xFF3C096C), // Manto púrpura oscuro
      'e': const Color(0xFF38B000), // Ojos vil verde
      'g': const Color(0xFF70E000), // Fuego de alma verde
      'c': const Color(0xFFFFD166), // Tiara/Corona
      's': const Color(0xFF5A189A), // Báculo lich
    },
    matrix: [
      '.....#####c#####..',
      '....#ccccccccc#...',
      '...#RR#kkkkk#RR#..',
      '..#RRR#k#e#k#RRR#.',
      '..#RRR#kkkkk#RRR#.',
      '..#RRR#K#g#K#RRR#.',
      '..#RRRRkkkkkRRRR#.',
      '...#RRR#rr#RRR#...',
      '..#gRRRRrrRRRRg#s#',
      '.#ggRRRRrrRRRRgg#s',
      '.#gRRRRRRRRRRRRg#s',
      '..#RRRRRRRRRRRR#s#',
      '..#RRRRrrRRRRRR#s#',
      '..#RRRRrrRRRRRR#s#',
      '.#RRRRRrrRRRRRRR#.',
      '.#RRRRRRRRRRRRRR#.',
      '.#rrrrrrrrrrrrrr#.',
      '.################.',
    ],
  );

  // ==========================================
  // ENEMIGO 8: ESPECTRO GÉLIDO (FROST WRAITH) - 16x18
  // ==========================================
  static final PixelSpriteData frostWraith = PixelSpriteData(
    visualId: 'frostWraith',
    width: 16,
    height: 18,
    palette: {
      '.': cTrans,
      '#': cBlack,
      'i': const Color(0xFF03045E), // Manto helado oscuro
      'I': const Color(0xFF0077B6), // Azul profundo
      'c': const Color(0xFF00B4D8), // Cian escarcha
      'C': const Color(0xFF90E0EF), // Hielo brillante
      'w': const Color(0xFFE0F7FA), // Nieve/Viento
      'e': const Color(0xFFFFFFFF), // Ojos espectrales blancos
    },
    matrix: [
      '.....######.....',
      '....#CCCCCC#....',
      '...#CcIIIIcC#...',
      '..#CcI#e##e#cC#.',
      '..#CcIIccIIcC#..',
      '..#CcIICCIICc#..',
      '...#CcCCCCcC#...',
      '..#w#CcIIcC#w#..',
      '.#ww#CcIIcC#ww#.',
      '.#w#CcIIIIcC#w#.',
      '..#CcIIIIIIcC#..',
      '..#CcIIIIIIcC#..',
      '.#CcIIIIIIIIcC#.',
      '.#CcIIIIIIIIcC#.',
      '#CcIIIIIIIIIIcC#',
      '#Cc#cC#cC#cC#cC#',
      '.##.##.##.##.##.',
      '................',
    ],
  );

  // ==========================================
  // EDIFICIO 1: CORAZÓN DE LA ALDEA (TOWN HALL) - 24x24
  // ==========================================
  static final PixelSpriteData townHall = PixelSpriteData(
    visualId: 'townHall',
    width: 24,
    height: 24,
    palette: {
      '.': cTrans,
      '#': cBlack,
      'r': const Color(0xFFD62828), // Tejado de tejas rojas
      'R': const Color(0xFFF77F00), // Brillo tejado
      'd': const Color(0xFF9D0208), // Sombra tejas
      'w': const Color(0xFFDDA15E), // Madera de las paredes
      'W': const Color(0xFFBC6C25), // Vigas de madera
      's': const Color(0xFF6C757D), // Muros de piedra base
      'S': const Color(0xFFADB5BD), // Piedra clara
      'g': const Color(0xFFFFD166), // Ventanas iluminadas / farol
      'b': const Color(0xFF1D3557), // Estandarte azul
      'B': const Color(0xFF457B9D),
      'c': const Color(0xFF495057), // Chimenea
      'p': const Color(0xFFE9ECEF), // Humo de chimenea
    },
    matrix: [
      '.........pp.............',
      '........ppp.............',
      '.......#cc#.............',
      '.......#cc#...#r#.......',
      '......##cc####rrr##.....',
      '.....#rrrrrrrrrrrrr#....',
      '....#rrrrrrrrrrrrrrr#...',
      '...#rrrrrrrrrrrrrrrrr#..',
      '..#rrrrdrdrdrdrdrdrrrr#.',
      '.#RRRRRRRRRRRRRRRRRRRR#.',
      '.#dddddddddddddddddddd#.',
      '..#WwWwWwWwWwWwWwWwWw#..',
      '..#w#g#w#bB#w#bB#w#g#w#.',
      '..#W#g#W#bB#W#bB#W#g#W#.',
      '..#w###w#bb#w#bb#w###w#.',
      '..#WwWwWwWwWwWwWwWwWw#..',
      '..#SSSSSSSSSSSSSSSSSS#..',
      '..#SsSsSs#WWWW#sSsSsS#..',
      '..#sSsSsS#WgWW#SsSsSs#..',
      '..#SsSsSs#WWWW#sSsSsS#..',
      '..#sSsSsS#WWWW#SsSsSs#..',
      '..#SSSSSS#WWWW#SSSSSS#..',
      '..#ssssss#WWWW#ssssss#..',
      '..####################..',
    ],
  );

  // ==========================================
  // EDIFICIO 2: TORRE DE GUARDIA DEFENSIVA - 16x20
  // ==========================================
  static final PixelSpriteData watchtower = PixelSpriteData(
    visualId: 'watchtower',
    width: 16,
    height: 20,
    palette: {
      '.': cTrans,
      '#': cBlack,
      'r': const Color(0xFFB02A37), // Tejadillo
      'R': const Color(0xFFDC3545),
      'w': const Color(0xFFDDA15E), // Madera
      'W': const Color(0xFF9A5E2E), // Vigas
      's': const Color(0xFF6C757D), // Piedra
      'S': const Color(0xFF495057),
      'f': const Color(0xFFFFC107), // Fuego antorcha
      'F': const Color(0xFFFF5722),
    },
    matrix: [
      '......#R#.......',
      '....#RRRRR#.....',
      '...#rrrrrrr#....',
      '..#rrrrrrrrr#...',
      '..#WWWWWWWWW#...',
      '..#w#w#w#w#w#...',
      '.#F#WwWwWwW#F#..',
      '.#f#WWWWWWW#f#..',
      '..###W#w#W###...',
      '....#W#w#W#.....',
      '....#W#w#W#.....',
      '....#W#w#W#.....',
      '....#WwWwW#.....',
      '...#SSSSSSS#....',
      '...#S#S#S#S#....',
      '...#s#s#s#s#....',
      '...#SSSSSSS#....',
      '...#sSsSsSs#....',
      '..#SSSSSSSSS#...',
      '..###########...',
    ],
  );

  // ==========================================
  // EDIFICIO 3: CABAÑA DE ALDEANO - 16x16
  // ==========================================
  static final PixelSpriteData cottage = PixelSpriteData(
    visualId: 'cottage',
    width: 16,
    height: 16,
    palette: {
      '.': cTrans,
      '#': cBlack,
      'r': const Color(0xFF7F4F24), // Techo de paja/madera
      'R': const Color(0xFF936639),
      'w': const Color(0xFFE9D8A6), // Muros de barro/madera
      'W': const Color(0xFFBB9457),
      'd': const Color(0xFF6B4226), // Puerta
      'g': const Color(0xFFFFD166), // Ventana
      's': const Color(0xFF6C757D), // Zócalo
    },
    matrix: [
      '.....#R#........',
      '....#RRR#.......',
      '...#RRRRR#......',
      '..#rrrrrrr#.....',
      '.#RRRRRRRRR#....',
      '#rrrrrrrrrrr#...',
      '#WWWWWWWWWWW#...',
      '#w#g#wWw#g#w#...',
      '#W#g#WwW#g#W#...',
      '#w###wWw###w#...',
      '#WWWW#d#WWWW#...',
      '#wWwW#d#wWwW#...',
      '#WWWW#d#WWWW#...',
      '#ssss#d#ssss#...',
      '#sssssssssss#...',
      '#############...',
    ],
  );

  // ==========================================
  // EDIFICIO 4: MINA DE CRISTALES (CRYSTAL MINE) - 24x24
  // ==========================================
  static final PixelSpriteData crystalMine = PixelSpriteData(
    visualId: 'crystalMine',
    width: 24,
    height: 24,
    palette: {
      '.': cTrans,
      '#': cBlack,
      's': const Color(0xFF4A4E69), // Piedra oscura cueva
      'S': const Color(0xFF9A8C98), // Piedra clara
      'w': const Color(0xFF582F0E), // Vigas de soporte
      'W': const Color(0xFF7F4F24), // Madera marco
      'c': const Color(0xFF00B4D8), // Cristal azul
      'C': const Color(0xFF90E0EF), // Cristal brillo
      'p': const Color(0xFF7209B7), // Cristal místico púrpura
      'P': const Color(0xFFF72585), // Brillo púrpura
      'g': const Color(0xFFFFD166), // Veta de oro
      'k': const Color(0xFF0D1B2A), // Fondo cueva profundo
    },
    matrix: [
      '.........#C#............',
      '........#CCC#...#P#.....',
      '.......#CcCcC#.#PPP#....',
      '......#s#CCC#s#pPpPp#...',
      '.....#sS#####Ss#P#p#....',
      '....#sSsWWWWWsSs#p#.....',
      '...#sSsWWWWWWWsSs#......',
      '..#sSsWW#kkk#WWsSs#.....',
      '.#sSsWW#kkkkk#WWsSs#....',
      '#sSsWW#kkkkkkk#WWsSs#...',
      '#sSWW#kkkkkkkkk#WWsS#...',
      '#sWW#kkkkkkkkkkk#WWs#...',
      '#sW#kkkkggkkkkkkk#Ws#...',
      '#sW#kkkggggkkkkkk#Ws#...',
      '#sW#kkkggkkkkpPkk#Ws#...',
      '#sW#kkkkkkkkpPPpk#Ws#...',
      '#sW#kcCkkkkk#p#kk#Ws#...',
      '#sW#cCCckkkkkkkkk#Ws#...',
      '#sW#cC#ckkkkkkkkk#Ws#...',
      '#sWW#c#kkkkkkkkk#WWs#...',
      '#sSsWW#kkkkkkkk#WWsSs#..',
      '#sSsSsWWWWWWWWWsSsSsS#..',
      '#SSSSSSSSSSSSSSSSSSSS#..',
      '######################..',
    ],
  );

  // ==========================================
  // EDIFICIO 5: TORRE DEL TRUENO (THUNDER TOWER) - 16x24
  // ==========================================
  static final PixelSpriteData thunderTower = PixelSpriteData(
    visualId: 'thunderTower',
    width: 16,
    height: 24,
    palette: {
      '.': cTrans,
      '#': cBlack,
      's': const Color(0xFF343A40), // Piedra oscura
      'S': const Color(0xFF6C757D), // Piedra torre
      'y': const Color(0xFFFFE600), // Rayo/Electricidad
      'Y': const Color(0xFFFFFFB3), // Destello eléctrico
      'c': const Color(0xFF00F5D4), // Orbe canalizador cian
      'C': const Color(0xFF80FFEA), // Resplandor cian
      'm': const Color(0xFF495057), // Anillos metálicos
      'M': const Color(0xFFADB5BD), // Metal claro
    },
    matrix: [
      '.......#Y#......',
      '......#yYY#.....',
      '.....#YcCcY#....',
      '....#YcCCCEY#...',
      '.....#cCCCc#....',
      '......#cCc#.....',
      '.....#mMMMm#....',
      '....#mMMMMMm#...',
      '....#Y#sSs#Y#...',
      '.....#ysSs#y#...',
      '....#mMMMMMm#...',
      '...#sSsSsSsSs#..',
      '...#SsSsSsSsS#..',
      '...#sS#mMm#Ss#..',
      '...#Ss#YyY#sS#..',
      '...#sS#mMm#Ss#..',
      '...#SsSsSsSsS#..',
      '...#mMMMMMMMm#..',
      '..#sSsSsSsSsSs#.',
      '..#SsSsSsSsSsS#.',
      '..#sSsSsSsSsSs#.',
      '.#SsSsSsSsSsSsS#',
      '.#SSSSSSSSSSSSS#',
      '.###############',
    ],
  );

  // ==========================================
  // EDIFICIO 6: MURALLA DE PIEDRA (STONE WALL) - 16x16
  // ==========================================
  static final PixelSpriteData stoneWall = PixelSpriteData(
    visualId: 'stoneWall',
    width: 16,
    height: 16,
    palette: {
      '.': cTrans,
      '#': cBlack,
      's': const Color(0xFF495057), // Piedra base
      'S': const Color(0xFF6C757D), // Piedra clara
      'w': const Color(0xFF7F4F24), // Vigas de madera
      'b': const Color(0xFF1D3557), // Estandarte
      'g': const Color(0xFFFFD166), // Escudo/Insignia oro
    },
    matrix: [
      '#SS##..##SS##..#',
      '#Ss##..##Ss##..#',
      '#SSSSSSSSSSSSSS#',
      '#sSsSsSsSsSsSsS#',
      '#SSSS#wWw#SSSSSS#',
      '#sSsS#wWw#sSsSsS#',
      '#SSSS#bgb#SSSSSS#',
      '#sSsS#bgb#sSsSsS#',
      '#SSSS#bgb#SSSSSS#',
      '#sSsS#bbb#sSsSsS#',
      '#SSSS#b#b#SSSSSS#',
      '#sSsS##.##sSsSsS#',
      '#SSSSSSSSSSSSSS#',
      '#sSsSsSsSsSsSsS#',
      '#SSSSSSSSSSSSSS#',
      '################',
    ],
  );

  // ==========================================
  // DECORACIÓN: ÁRBOL FRONDOSO - 16x18
  // ==========================================
  static final PixelSpriteData forestTree = PixelSpriteData(
    visualId: 'forestTree',
    width: 16,
    height: 18,
    palette: {
      '.': cTrans,
      '#': cBlack,
      'g': const Color(0xFF2D6A4F), // Copa árbol
      'G': const Color(0xFF40916C), // Copa brillante
      'd': const Color(0xFF1B4332), // Sombra hojas
      't': const Color(0xFF52B788), // Brillo alto
      'w': const Color(0xFF7F4F24), // Tronco
      'W': const Color(0xFF582F0E), // Tronco oscuro
    },
    matrix: [
      '.....######.....',
      '...##ttGGtt##...',
      '..#ttGGGGGGtt#..',
      '.#GGGGGGGGGGGG#.',
      '#GGGGddddGGGGGG#',
      '#GGddddddddGGGG#',
      '#GGddGGGGddddGG#',
      '.#GGGGGGGGGGGG#.',
      '..#dGGddddGGd#..',
      '...#dddddddd#...',
      '.....#WwwW#.....',
      '.....#WwwW#.....',
      '.....#WwwW#.....',
      '.....#WwwW#.....',
      '....#WWwwWW#....',
      '...#WWWwwWWW#...',
      '..#WWWWwwWWWW#..',
      '..############..',
    ],
  );

  // ==========================================
  // ÍCONOS DE ÍTEMS PARA COMERCIO / TIENDA
  // ==========================================

  // 1. POCIÓN DE VIDA (HEALTH POTION) - 14x14
  static final PixelSpriteData potionHealth = PixelSpriteData(
    visualId: 'potionHealth',
    width: 14,
    height: 14,
    palette: {
      '.': cTrans,
      '#': cBlack,
      'w': const Color(0xFF7F4F24), // Corcho
      'g': const Color(0xFFE0F7FA), // Cristal frasco
      'r': const Color(0xFFD90429), // Líquido rojo
      'R': const Color(0xFFEF233C), // Líquido brillante
      'W': Colors.white, // Destello cristal
    },
    matrix: [
      '.....####.....',
      '.....#ww#.....',
      '....#gggg#....',
      '....#gggg#....',
      '..###gggg###..',
      '.#ggWWrrrrgg#.',
      '#ggWWrrrrRRgg#',
      '#ggWrrrrRRRRg#',
      '#ggrrrrRRRRRg#',
      '#ggrrrrrrrrRg#',
      '#ggrrrrrrrrrg#',
      '.#ggrrrrrrrg#.',
      '..#gggggggg#..',
      '....######....',
    ],
  );

  // 2. POCIÓN DE MANÁ (MANA POTION) - 14x14
  static final PixelSpriteData potionMana = PixelSpriteData(
    visualId: 'potionMana',
    width: 14,
    height: 14,
    palette: {
      '.': cTrans,
      '#': cBlack,
      'w': const Color(0xFF7F4F24), // Corcho
      'g': const Color(0xFFE0F7FA), // Cristal
      'b': const Color(0xFF0077B6), // Azul maná
      'B': const Color(0xFF00B4D8), // Azul brillante
      'W': Colors.white, // Destello
    },
    matrix: [
      '.....####.....',
      '.....#ww#.....',
      '....#gggg#....',
      '....#gggg#....',
      '..###gggg###..',
      '.#ggWWbbbbgg#.',
      '#ggWWbbbbBBgg#',
      '#ggWbbbbBBBBg#',
      '#ggbbbbBBBBBg#',
      '#ggbbbbbbbbBg#',
      '#ggbbbbbbbbbg#',
      '.#ggbbbbbbbg#.',
      '..#gggggggg#..',
      '....######....',
    ],
  );

  // 3. CRISTAL MÁGICO / GEMA (MAGIC CRYSTAL / GEM) - 14x14
  static final PixelSpriteData crystalGem = PixelSpriteData(
    visualId: 'crystalGem',
    width: 14,
    height: 14,
    palette: {
      '.': cTrans,
      '#': cBlack,
      'c': const Color(0xFF00F5D4), // Turquesa cian
      'C': const Color(0xFF70E000), // Brillo esmeralda
      'w': Colors.white, // Destello estelar
      'd': const Color(0xFF0077B6), // Sombra faceta
    },
    matrix: [
      '.....####.....',
      '....#wCcc#....',
      '...#wwCCccc#..',
      '..#wwwCCCccc#.',
      '.#wwwwCCCCccc#',
      '#wwwwwCCCCddd#',
      '#wCCCdddddddd#',
      '.#CCCddddddd#.',
      '..#CCdddddd#..',
      '...#Cddddd#...',
      '....#Cddd#....',
      '.....#Cd#.....',
      '......##......',
      '..............',
    ],
  );

  // 4. MONEDA DE ORO (GOLD COIN) - 14x14
  static final PixelSpriteData goldCoin = PixelSpriteData(
    visualId: 'goldCoin',
    width: 14,
    height: 14,
    palette: {
      '.': cTrans,
      '#': cBlack,
      'g': const Color(0xFFFFB703), // Oro base
      'G': const Color(0xFFFFE6A7), // Oro brillo
      'd': const Color(0xFFFB8500), // Oro sombra
      'W': Colors.white, // Destello
    },
    matrix: [
      '....######....',
      '..#GGGGGGGG#..',
      '.#GGWGGGGGGGd#',
      '#GGWWgGGGggggd#',
      '#GGWg#gggg#ggd#',
      '#GGGg#gggg#ggd#',
      '#GGGg#gggg#ggd#',
      '#GGGg######ggd#',
      '#GGGgggggggggd#',
      '#GGGgggggggggd#',
      '.#GGggggggggd#',
      '..#dddddddd#..',
      '....######....',
      '..............',
    ],
  );

  // 5. COFRE DE TESORO (TREASURE CHEST) - 16x16
  static final PixelSpriteData treasureChest = PixelSpriteData(
    visualId: 'treasureChest',
    width: 16,
    height: 16,
    palette: {
      '.': cTrans,
      '#': cBlack,
      'w': const Color(0xFF7F4F24), // Madera cofre
      'W': const Color(0xFF936639), // Madera clara
      'g': const Color(0xFFFFD166), // Herrajes oro
      'G': const Color(0xFFFFE6A7), // Oro brillo
      'c': const Color(0xFF00F5D4), // Gema de la cerradura
    },
    matrix: [
      '.....######.....',
      '....#WWWWWW#....',
      '...#WwWwWwWw#...',
      '..#gggggggggg#..',
      '..#gGgGgGgGgG#..',
      '..#wWwWwWwWwW#..',
      '..#WwWwWwWwWw#..',
      '..#gggggggggg#..',
      '..#gGg#cCc#gG#..',
      '..#gGg#CCC#gG#..',
      '..#wWw#cCc#Ww#..',
      '..#WwWw###wWw#..',
      '..#gggggggggg#..',
      '..#wWwWwWwWwW#..',
      '..#WwWwWwWwWw#..',
      '..############..',
    ],
  );

  // 6. ESPADA LEGENDARIA (LEGENDARY SWORD) - 16x16
  static final PixelSpriteData legendarySword = PixelSpriteData(
    visualId: 'legendarySword',
    width: 16,
    height: 16,
    palette: {
      '.': cTrans,
      '#': cBlack,
      's': const Color(0xFFC0C0D0), // Hoja acero
      'S': Colors.white, // Filo resplandeciente
      'g': const Color(0xFFFFD166), // Empuñadura oro
      'r': const Color(0xFFD90429), // Gema pomo
      'b': const Color(0xFF00B4D8), // Guarda mística
    },
    matrix: [
      '..............S#',
      '.............Ss#',
      '............Ss#.',
      '...........Ss#..',
      '..........Ss#...',
      '.........Ss#....',
      '........Ss#.....',
      '.......Ss#......',
      '......Ss#.......',
      '.....b#b#.......',
      '....#bbb#.......',
      '...#ggggg#......',
      '....#g#g#.......',
      '.....#r#........',
      '......##........',
      '................',
    ],
  );

  // 7. ESCUDO REAL (ROYAL SHIELD) - 16x16
  static final PixelSpriteData royalShield = PixelSpriteData(
    visualId: 'royalShield',
    width: 16,
    height: 16,
    palette: {
      '.': cTrans,
      '#': cBlack,
      'g': const Color(0xFFFFD166), // Borde oro
      'G': const Color(0xFFFFE6A7),
      'b': const Color(0xFF1D3557), // Fondo azul
      'B': const Color(0xFF457B9D),
      'w': Colors.white, // Blasón central
      'r': const Color(0xFFD90429),
    },
    matrix: [
      '..############..',
      '.#gGgGgGgGgGgG#.',
      '#gGbbbbbbbbGGg#',
      '#gGbBbwwbBbGGg#',
      '#gGbwwWWbbGGg#',
      '#gGbwwrRwwbGGg#',
      '#gGbwwrRwwbGGg#',
      '#gGbbwwWWbbGGg#',
      '#gGbBbwwbBbGGg#',
      '.#gGbbbbbbGGg#..',
      '..#gGbbbbGGg#...',
      '...#gGbbGGg#....',
      '....#gGGg#......',
      '.....#gG#.......',
      '......##........',
      '................',
    ],
  );

  // 8. LIBRO DE HECHIZOS (SPELLBOOK) - 16x16
  static final PixelSpriteData spellBook = PixelSpriteData(
    visualId: 'spellBook',
    width: 16,
    height: 16,
    palette: {
      '.': cTrans,
      '#': cBlack,
      'p': const Color(0xFF5A189A), // Cuero púrpura
      'P': const Color(0xFF7B2CBF),
      'g': const Color(0xFFFFD166), // Esquinas oro / estrella
      'w': const Color(0xFFE9ECEF), // Páginas
      'r': const Color(0xFFD90429), // Marcador de páginas rojo
    },
    matrix: [
      '.....######.....',
      '....#ggPPgg#....',
      '...#gPPPPPPg#...',
      '..#gPP#g#PPg#...',
      '..#PPPgggPPP#...',
      '..#PPggGggPP#...',
      '..#PPPgggPPP#...',
      '..#gPP#g#PPg#...',
      '..#gPPPPPPg#w#..',
      '...#ggPPgg#ww#..',
      '....#PPPP#ww#r#.',
      '....#PPPP#w#rr#.',
      '....#PPPP##.##..',
      '....#pppp#......',
      '....######......',
      '................',
    ],
  );

  // ==========================================
  // 9. NPCS ISEKAI (HERRERO, COMERCIANTE, GREMIO, GUARDIÁN)
  // ==========================================
  static final PixelSpriteData npcBlacksmith = PixelSpriteData(
    visualId: 'npcBlacksmith',
    width: 16,
    height: 16,
    palette: {
      '.': cTrans,
      '#': cBlack,
      'k': cSkin,
      's': const Color(0xFF8D99AE), // Delantal de cuero y hierro
      'S': const Color(0xFF2B2D42),
      'o': const Color(0xFFFF5400), // Martillo caliente
      'g': const Color(0xFFFFD166),
    },
    matrix: [
      '.....######.....',
      '....#kkkkkk#....',
      '...#k#e##e#k#...',
      '...#kkkkkkkk#...',
      '....#ssssss#....',
      '...#SssssssS#...',
      '..#SSssssssSS#..',
      '..#SSssssssSS#g#',
      '..#S#ssssss#S#o#',
      '...#ssssssss#..#',
      '...#SSSSSSSS#...',
      '....#SS##SS#....',
      '....#SS##SS#....',
      '...#SSS##SSS#...',
      '..####....####..',
      '................',
    ],
  );

  static final PixelSpriteData npcMerchant = PixelSpriteData(
    visualId: 'npcMerchant',
    width: 16,
    height: 16,
    palette: {
      '.': cTrans,
      '#': cBlack,
      'k': cSkin,
      't': const Color(0xFF2A9D8F), // Túnica de mercader turquesa
      'T': const Color(0xFFE76F51), // Sombrero de viaje
      'g': const Color(0xFFFFD166), // Sacos de oro
    },
    matrix: [
      '....########....',
      '..#TTTTTTTTTT#..',
      '..#TT######TT#..',
      '...#kkkkkkkk#...',
      '...#k#e##e#k#...',
      '...#kkkkkkkk#...',
      '..#tttttttttt#..',
      '.#tttttttttttt#.',
      '#g#tttttttttt#g#',
      '#gg#tttttttt#gg#',
      '.#g#tttttttt#g#.',
      '..#tttttttttt#..',
      '...#tttttttt#...',
      '....#tt##tt#....',
      '....####.####...',
      '................',
    ],
  );

  static final PixelSpriteData npcQuestGiver = PixelSpriteData(
    visualId: 'npcQuestGiver',
    width: 16,
    height: 16,
    palette: {
      '.': cTrans,
      '#': cBlack,
      'k': cSkin,
      'w': const Color(0xFFEDF2F4), // Barba blanca sabio
      'b': const Color(0xFF1D3557), // Túnica arcana azul
      'g': const Color(0xFFFFD166), // Pergamino de misión
    },
    matrix: [
      '.....######.....',
      '....#bbbbbb#....',
      '...#bkkkkkkb#...',
      '...#k#e##e#k#...',
      '...#kwwwwwwk#...',
      '...#wwwwwwww#...',
      '..#bbwwwwwwbb#..',
      '.#bbb#bbbb#bbb#.',
      '.#bbb#gggg#bbb#.',
      '.#bbb#gggg#bbb#.',
      '..#bb#gggg#bb#..',
      '...#bbbbbbbb#...',
      '...#bbbbbbbb#...',
      '....#bb##bb#....',
      '....####.####...',
      '................',
    ],
  );
}
