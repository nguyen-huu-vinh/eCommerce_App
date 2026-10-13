class MockData {
  // BẮT BUỘC phải có từ khóa static để gọi trực tiếp MockData.categories
  // Trong class MockData:
  // Trong class MockData:

  static const List<Map<String, dynamic>> allProducts = [
    {
      'title': 'Black Winter...',
      'description': 'Autumn And Winter Casual cotton-padded jacket...',
      'price': '499',
      'rating': 4.5,
      'ratingCount': 4422,
      'image': 'assets/images/unsplash_NoVnXXmDNi0.png',
    },
    {
      'title': 'Mens Starry',
      'description': 'Mens Starry Sky Printed Shirt 100% Cotton Fabric',
      'price': '399',
      'originalPrice': '899',
      'discount': '55% off',
      'rating': 4.5,
      'ratingCount': 2345,
      'image': 'assets/images/unsplash_0vsk2_9dkqo.png',
    },
    {
      'title': 'Black Dress',
      'description': 'Solid Black Dress for Women, Sexy Chain Straps Laced...',
      'price': '2000',
      'rating': 4.8,
      'ratingCount': 3123,
      'image': 'assets/images/unsplash_yTBMYCcZQRs.png',
    },
    {
      'title': 'Pink Embroide...',
      'description': 'EARTHEN Rose Pink Embroidered Tassel Wear...',
      'price': '1900',
      'rating': 4.2,
      'ratingCount': 1421,
      'image': 'assets/images/unsplash_Pdds9XsWyoM.png',
    },
    {
      'title': 'Flare Dress',
      'description': 'Anneesh Black & Rust Orange Rose Print Tiered Mid F...',
      'price': '1990',
      'rating': 4.6,
      'ratingCount': 5849,
      'image': 'assets/images/unsplash_9U18fiowwbw.png',
    },
    {
      'title': 'denim dress',
      'description':
          'Blue cotton denim dress wearing 2 in 1 mixed cotton at...',
      'price': '999',
      'rating': 4.3,
      'ratingCount': 2734,
      'image': 'assets/images/unsplash_0vsk2_9dkqo (1).png',
    },
  ];

  static const List<Map<String, dynamic>> trendingProducts = [
    {
      'title': "IWC Schaffhausen 2021 Pilot's Watch \"SIHH 2019\" 44mm",
      'description': '',
      'price': '650',
      'originalPrice': '1599',
      'discount': '60% off',
      'image': 'assets/images/Mask Group (1).png',
    },
    {
      'title': 'Labbin White Sneakers For Men and Female',
      'description': '',
      'price': '650',
      'originalPrice': '1250',
      'discount': '70% off',
      'image': 'assets/images/Mask Group (2).png',
    },
    {
      'title': 'Mammon Handbag (Set of...',
      'description': '',
      'price': '750',
      'originalPrice': '1999',
      'discount': '60% off',
      'image': 'assets/images/Mask Group (2).png',
    },
  ];
  static const List<Map<String, String>> categories = [
    {'title': 'Beauty', 'image': 'assets/images/Ellipse 4.png'},
    {'title': 'Fashion', 'image': 'assets/images/unsplash__3Q3tsJ01nc.png'},
    {'title': 'Kids', 'image': 'assets/images/unsplash_GCDjllzoKLo.png'},
    {'title': 'Mens', 'image': 'assets/images/unsplash_OYYE4g-I5ZQ.png'},
    {'title': 'Womens', 'image': 'assets/images/unsplash_xPJYL0l5Ii8.png'},
  ];

  static const List<Map<String, dynamic>> dealProducts = [
    {
      'title': 'Women Printed Kurta',
      'description': 'Neque porro quisquam est qui dolorem ipsum quia',
      'price': '1500',
      'originalPrice': '2499',
      'discount': '40%Off',
      'rating': 4.0,
      'ratingCount': 56890,
      'image': 'assets/images/Mask Group.png',
    },
    {
      'title': 'HRX by Hrithik Roshan',
      'description': 'Neque porro quisquam est qui dolorem ipsum quia',
      'price': '2499',
      'originalPrice': '4999',
      'discount': '50%Off',
      'rating': 4.0,
      'ratingCount': 344567,
      'image': 'assets/images/image 15.png',
    },
    {
      'title': 'HRX by Hrithik Roshan',
      'description': 'Neque porro quisquam est qui dolorem ipsum quia',
      'price': '2499',
      'originalPrice': '4999',
      'discount': '50%Off',
      'rating': 4.0,
      'ratingCount': 344567,
      'image': 'assets/images/Mask Group.png',
    },
  ];
}
