class Review {
  final String id;
  final String userName;
  final String userImageUrl;
  final double rating;
  final DateTime date;
  final String comment;
  final List<String>? images;

  Review({
    required this.id,
    required this.userName,
    required this.userImageUrl,
    required this.rating,
    required this.date,
    required this.comment,
    this.images,
  });
}

final mockReviews = [
  Review(
    id: '1',
    userName: 'Jane Cooper',
    userImageUrl: 'https://i.pravatar.cc/150?u=jane',
    rating: 5.0,
    date: DateTime(2024, 3, 15),
    comment: 'Absolutely stunning place! The view was even better than the pictures. The host was very responsive and helpful with local recommendations. Clean, cozy, and perfectly located.',
  ),
  Review(
    id: '2',
    userName: 'Robert Fox',
    userImageUrl: 'https://i.pravatar.cc/150?u=robert',
    rating: 4.5,
    date: DateTime(2024, 3, 2),
    comment: 'Great stay overall. The location is perfect for exploring the area. Only minor issue was the Wifi being a bit slow at times, but everything else was top-notch.',
    images: ['https://images.unsplash.com/photo-1518780664697-55e3ad937233?q=80&w=400'],
  ),
  Review(
    id: '3',
    userName: 'Esther Howard',
    userImageUrl: 'https://i.pravatar.cc/150?u=esther',
    rating: 5.0,
    date: DateTime(2024, 2, 20),
    comment: 'One of the best airbnbs I have ever stayed in. The attention to detail is amazing. It felt like a 5-star hotel but with the comfort of a home. Highly recommend!',
  ),
  Review(
    id: '4',
    userName: 'Cameron Williamson',
    userImageUrl: 'https://i.pravatar.cc/150?u=cameron',
    rating: 4.0,
    date: DateTime(2024, 2, 10),
    comment: 'Solid experience. The price is bit high but the quality matches it. Host was kind enough to allow a slightly later checkout.',
  ),
  Review(
    id: '5',
    userName: 'Jenny Wilson',
    userImageUrl: 'https://i.pravatar.cc/150?u=jenny',
    rating: 5.0,
    date: DateTime(2024, 1, 25),
    comment: 'Perfect for a family getaway. The kids loved the open space and the kitchen had everything we needed to cook our own meals.',
  ),
];
