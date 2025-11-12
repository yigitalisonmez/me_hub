import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Collection of Lucide Icons for routine items
class RoutineIcons {
  RoutineIcons._();

  /// Get icon from codePoint
  static IconData? getIconFromCodePoint(int codePoint) {
    try {
      for (var iconData in allIcons) {
        final icon = iconData['icon'] as IconData;
        if (icon.codePoint == codePoint) {
          return icon;
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  static final List<Map<String, dynamic>> allIcons = [
    // Health & Fitness
    {'icon': LucideIcons.droplet, 'name': 'water'},
    {'icon': LucideIcons.droplets, 'name': 'hydrate'},
    {'icon': LucideIcons.dumbbell, 'name': 'fitness'},
    {'icon': LucideIcons.heart, 'name': 'health'},
    {'icon': LucideIcons.heartPulse, 'name': 'heart rate'},
    {'icon': LucideIcons.activity, 'name': 'activity'},
    {'icon': LucideIcons.zap, 'name': 'energy'},
    {'icon': LucideIcons.flame, 'name': 'burn'},
    {'icon': LucideIcons.trophy, 'name': 'trophy'},
    {'icon': LucideIcons.target, 'name': 'target'},
    {'icon': LucideIcons.award, 'name': 'award'},
    {'icon': LucideIcons.move, 'name': 'exercise'},
    {'icon': LucideIcons.bike, 'name': 'bike'},
    
    // Food & Drink
    {'icon': LucideIcons.coffee, 'name': 'coffee'},
    {'icon': LucideIcons.utensils, 'name': 'meal'},
    {'icon': LucideIcons.utensilsCrossed, 'name': 'dining'},
    {'icon': LucideIcons.pizza, 'name': 'pizza'},
    {'icon': LucideIcons.sandwich, 'name': 'sandwich'},
    {'icon': LucideIcons.salad, 'name': 'salad'},
    {'icon': LucideIcons.apple, 'name': 'apple'},
    {'icon': LucideIcons.cherry, 'name': 'cherry'},
    {'icon': LucideIcons.cookie, 'name': 'cookie'},
    {'icon': LucideIcons.cake, 'name': 'cake'},
    {'icon': LucideIcons.candy, 'name': 'ice cream'},
    {'icon': LucideIcons.egg, 'name': 'egg'},
    {'icon': LucideIcons.beef, 'name': 'beef'},
    {'icon': LucideIcons.fish, 'name': 'fish'},
    {'icon': LucideIcons.milk, 'name': 'milk'},
    {'icon': LucideIcons.wine, 'name': 'wine'},
    {'icon': LucideIcons.glassWater, 'name': 'glass water'},
    {'icon': LucideIcons.soup, 'name': 'soup'},
    
    // Sleep & Rest
    {'icon': LucideIcons.moon, 'name': 'moon'},
    {'icon': LucideIcons.bed, 'name': 'bed'},
    {'icon': LucideIcons.bedDouble, 'name': 'rest'},
    {'icon': LucideIcons.bedSingle, 'name': 'nap'},
    
    // Work & Study
    {'icon': LucideIcons.briefcase, 'name': 'work'},
    {'icon': LucideIcons.laptop, 'name': 'laptop'},
    {'icon': LucideIcons.monitor, 'name': 'computer'},
    {'icon': LucideIcons.book, 'name': 'book'},
    {'icon': LucideIcons.bookOpen, 'name': 'read'},
    {'icon': LucideIcons.bookMarked, 'name': 'bookmark'},
    {'icon': LucideIcons.graduationCap, 'name': 'education'},
    {'icon': LucideIcons.library, 'name': 'library'},
    {'icon': LucideIcons.pencil, 'name': 'pencil'},
    {'icon': LucideIcons.penTool, 'name': 'pen'},
    {'icon': LucideIcons.fileText, 'name': 'document'},
    {'icon': LucideIcons.clipboardList, 'name': 'checklist'},
    {'icon': LucideIcons.clipboard, 'name': 'clipboard'},
    {'icon': LucideIcons.stickyNote, 'name': 'notes'},
    
    // Time & Planning
    {'icon': LucideIcons.clock, 'name': 'clock'},
    {'icon': LucideIcons.timer, 'name': 'timer'},
    {'icon': LucideIcons.alarmClock, 'name': 'alarm'},
    {'icon': LucideIcons.calendar, 'name': 'calendar'},
    {'icon': LucideIcons.calendarDays, 'name': 'days'},
    {'icon': LucideIcons.calendarCheck, 'name': 'schedule'},
    {'icon': LucideIcons.hourglass, 'name': 'hourglass'},
    {'icon': LucideIcons.watch, 'name': 'watch'},
    
    // Weather & Nature
    {'icon': LucideIcons.sun, 'name': 'sun'},
    {'icon': LucideIcons.sunrise, 'name': 'sunrise'},
    {'icon': LucideIcons.sunset, 'name': 'sunset'},
    {'icon': LucideIcons.cloud, 'name': 'cloud'},
    {'icon': LucideIcons.cloudRain, 'name': 'rain'},
    {'icon': LucideIcons.cloudSnow, 'name': 'snow'},
    {'icon': LucideIcons.wind, 'name': 'wind'},
    {'icon': LucideIcons.sparkles, 'name': 'sparkles'},
    {'icon': LucideIcons.star, 'name': 'star'},
    {'icon': LucideIcons.treePine, 'name': 'tree'},
    {'icon': LucideIcons.trees, 'name': 'trees'},
    {'icon': LucideIcons.flower, 'name': 'flower'},
    {'icon': LucideIcons.leaf, 'name': 'leaf'},
    {'icon': LucideIcons.mountain, 'name': 'mountain'},
    {'icon': LucideIcons.waves, 'name': 'waves'},
    
    // Communication
    {'icon': LucideIcons.messageCircle, 'name': 'message'},
    {'icon': LucideIcons.messageSquare, 'name': 'chat'},
    {'icon': LucideIcons.mail, 'name': 'email'},
    {'icon': LucideIcons.phone, 'name': 'phone'},
    {'icon': LucideIcons.phoneCall, 'name': 'call'},
    {'icon': LucideIcons.video, 'name': 'video'},
    {'icon': LucideIcons.bell, 'name': 'notification'},
    {'icon': LucideIcons.bellRing, 'name': 'alert'},
    {'icon': LucideIcons.megaphone, 'name': 'announce'},
    {'icon': LucideIcons.mic, 'name': 'microphone'},
    
    // Home & Living
    {'icon': LucideIcons.house, 'name': 'home'},
    {'icon': LucideIcons.armchair, 'name': 'chair'},
    {'icon': LucideIcons.lamp, 'name': 'lamp'},
    {'icon': LucideIcons.lightbulb, 'name': 'lightbulb'},
    {'icon': LucideIcons.sofa, 'name': 'sofa'},
    {'icon': LucideIcons.bath, 'name': 'bath'},
    {'icon': LucideIcons.showerHead, 'name': 'shower'},
    {'icon': LucideIcons.washingMachine, 'name': 'laundry'},
    {'icon': LucideIcons.cookingPot, 'name': 'cooking'},
    {'icon': LucideIcons.microwave, 'name': 'microwave'},
    {'icon': LucideIcons.refrigerator, 'name': 'fridge'},
    {'icon': LucideIcons.trash, 'name': 'trash'},
    
    // Entertainment
    {'icon': LucideIcons.music, 'name': 'music'},
    {'icon': LucideIcons.headphones, 'name': 'headphones'},
    {'icon': LucideIcons.guitar, 'name': 'guitar'},
    {'icon': LucideIcons.film, 'name': 'movie'},
    {'icon': LucideIcons.tv, 'name': 'tv'},
    {'icon': LucideIcons.gamepad2, 'name': 'gaming'},
    {'icon': LucideIcons.camera, 'name': 'camera'},
    {'icon': LucideIcons.image, 'name': 'photo'},
    {'icon': LucideIcons.palette, 'name': 'art'},
    {'icon': LucideIcons.paintbrush, 'name': 'paint'},
    {'icon': LucideIcons.scissors, 'name': 'craft'},
    
    // Shopping & Money
    {'icon': LucideIcons.shoppingCart, 'name': 'shopping'},
    {'icon': LucideIcons.shoppingBag, 'name': 'bag'},
    {'icon': LucideIcons.wallet, 'name': 'wallet'},
    {'icon': LucideIcons.creditCard, 'name': 'card'},
    {'icon': LucideIcons.banknote, 'name': 'money'},
    {'icon': LucideIcons.coins, 'name': 'coins'},
    {'icon': LucideIcons.piggyBank, 'name': 'savings'},
    {'icon': LucideIcons.gift, 'name': 'gift'},
    {'icon': LucideIcons.tag, 'name': 'tag'},
    {'icon': LucideIcons.percent, 'name': 'discount'},
    
    // Transportation
    {'icon': LucideIcons.car, 'name': 'car'},
    {'icon': LucideIcons.bus, 'name': 'bus'},
    {'icon': LucideIcons.trainFront, 'name': 'train'},
    {'icon': LucideIcons.plane, 'name': 'plane'},
    {'icon': LucideIcons.ship, 'name': 'ship'},
    {'icon': LucideIcons.mapPin, 'name': 'location'},
    {'icon': LucideIcons.map, 'name': 'map'},
    {'icon': LucideIcons.compass, 'name': 'compass'},
    {'icon': LucideIcons.navigation, 'name': 'navigate'},
    
    // Wellness & Care
    {'icon': LucideIcons.pill, 'name': 'medicine'},
    {'icon': LucideIcons.stethoscope, 'name': 'doctor'},
    {'icon': LucideIcons.syringe, 'name': 'injection'},
    {'icon': LucideIcons.thermometer, 'name': 'temperature'},
    {'icon': LucideIcons.bandage, 'name': 'bandage'},
    {'icon': LucideIcons.cross, 'name': 'medical'},
    {'icon': LucideIcons.smile, 'name': 'happy'},
    {'icon': LucideIcons.frown, 'name': 'sad'},
    {'icon': LucideIcons.meh, 'name': 'neutral'},
    
    // Productivity
    {'icon': LucideIcons.circleCheck, 'name': 'check'},
    {'icon': LucideIcons.checkCheck, 'name': 'done'},
    {'icon': LucideIcons.circle, 'name': 'circle'},
    {'icon': LucideIcons.square, 'name': 'square'},
    {'icon': LucideIcons.flag, 'name': 'flag'},
    {'icon': LucideIcons.bookmark, 'name': 'bookmark'},
    {'icon': LucideIcons.pin, 'name': 'pin'},
    {'icon': LucideIcons.key, 'name': 'key'},
    {'icon': LucideIcons.lock, 'name': 'lock'},
    {'icon': LucideIcons.lockOpen, 'name': 'unlock'},
    {'icon': LucideIcons.eye, 'name': 'view'},
    {'icon': LucideIcons.eyeOff, 'name': 'hide'},
    
    // Tech & Tools
    {'icon': LucideIcons.smartphone, 'name': 'phone'},
    {'icon': LucideIcons.tablet, 'name': 'tablet'},
    {'icon': LucideIcons.battery, 'name': 'battery'},
    {'icon': LucideIcons.wifi, 'name': 'wifi'},
    {'icon': LucideIcons.bluetooth, 'name': 'bluetooth'},
    {'icon': LucideIcons.usb, 'name': 'usb'},
    {'icon': LucideIcons.download, 'name': 'download'},
    {'icon': LucideIcons.upload, 'name': 'upload'},
    {'icon': LucideIcons.settings, 'name': 'settings'},
    {'icon': LucideIcons.wrench, 'name': 'tool'},
    {'icon': LucideIcons.hammer, 'name': 'hammer'},
    
    // Social & People
    {'icon': LucideIcons.user, 'name': 'user'},
    {'icon': LucideIcons.users, 'name': 'people'},
    {'icon': LucideIcons.userPlus, 'name': 'add user'},
    {'icon': LucideIcons.share2, 'name': 'share'},
    {'icon': LucideIcons.userRound, 'name': 'profile'},
    {'icon': LucideIcons.baby, 'name': 'baby'},
    {'icon': LucideIcons.crown, 'name': 'crown'},
    
    // Miscellaneous
    {'icon': LucideIcons.infinity, 'name': 'infinite'},
    {'icon': LucideIcons.shield, 'name': 'protect'},
    {'icon': LucideIcons.umbrella, 'name': 'umbrella'},
    {'icon': LucideIcons.glasses, 'name': 'glasses'},
    {'icon': LucideIcons.shirt, 'name': 'shirt'},
    {'icon': LucideIcons.footprints, 'name': 'footprints'},
    {'icon': LucideIcons.pawPrint, 'name': 'pet'},
    {'icon': LucideIcons.bone, 'name': 'bone'},
    {'icon': LucideIcons.rocket, 'name': 'rocket'},
    {'icon': LucideIcons.package, 'name': 'package'},
    {'icon': LucideIcons.archive, 'name': 'archive'},
    {'icon': LucideIcons.folder, 'name': 'folder'},
    {'icon': LucideIcons.file, 'name': 'file'},
    {'icon': LucideIcons.scan, 'name': 'scan'},
    {'icon': LucideIcons.printer, 'name': 'print'},
    {'icon': LucideIcons.repeat, 'name': 'repeat'},
    {'icon': LucideIcons.refreshCw, 'name': 'refresh'},
    {'icon': LucideIcons.history, 'name': 'history'},
    {'icon': LucideIcons.plus, 'name': 'plus'},
    {'icon': LucideIcons.minus, 'name': 'minus'},
    {'icon': LucideIcons.x, 'name': 'close'},
    {'icon': LucideIcons.check, 'name': 'checkmark'},
    {'icon': LucideIcons.trash2, 'name': 'delete'},
    {'icon': LucideIcons.pencil, 'name': 'edit'},
    {'icon': LucideIcons.save, 'name': 'save'},
    {'icon': LucideIcons.search, 'name': 'search'},
    {'icon': LucideIcons.listFilter, 'name': 'filter'},
    {'icon': LucideIcons.arrowLeft, 'name': 'back'},
    {'icon': LucideIcons.arrowRight, 'name': 'forward'},
    {'icon': LucideIcons.arrowUp, 'name': 'up'},
    {'icon': LucideIcons.arrowDown, 'name': 'down'},
    {'icon': LucideIcons.chevronRight, 'name': 'next'},
    {'icon': LucideIcons.chevronLeft, 'name': 'previous'},
    {'icon': LucideIcons.ellipsisVertical, 'name': 'more'},
    {'icon': LucideIcons.menu, 'name': 'menu'},
    {'icon': LucideIcons.grip, 'name': 'grid'},
    {'icon': LucideIcons.list, 'name': 'list'},
  ];
}
