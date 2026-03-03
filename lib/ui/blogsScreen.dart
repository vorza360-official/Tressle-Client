import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class BlogsScreen extends StatelessWidget {
  final List<BlogPost> blogPosts = [
    BlogPost(
      id: '1',
      title: '5 Essential Hair Care Tips for Summer',
      content: '''
Summer brings sunshine and outdoor fun, but it can also wreak havoc on your hair. The combination of sun, chlorine, and humidity can leave your locks dry, frizzy, and damaged. Here are 5 essential tips to keep your hair healthy all summer long:

1. **Hydrate, Hydrate, Hydrate:** Just like your skin, your hair needs extra moisture during summer. Use a deep conditioning treatment once a week to replenish lost moisture.

2. **Protect from UV Rays:** Your hair needs sun protection too! Look for hair products with UV filters or wear a hat when spending extended time outdoors.

3. **Chlorine Protection:** Before swimming, wet your hair with clean water and apply a leave-in conditioner. This creates a barrier that minimizes chlorine absorption.

4. **Limit Heat Styling:** Give your hair a break from hot tools. Embrace natural styles or opt for heat-free styling methods.

5. **Regular Trims:** Schedule regular trims every 6-8 weeks to prevent split ends from traveling up the hair shaft.

Remember, healthy hair starts with proper care and the right products. Visit your favorite Tressle salon for personalized hair care advice!''',
      author: 'Sarah Johnson',
      date: 'December 15, 2024',
      readTime: '5 min read',
      imageUrl:
          'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=800',
      category: 'Hair Care',
    ),
    BlogPost(
      id: '2',
      title: 'The Rise of Men\'s Grooming: A New Era of Self-Care',
      content: '''
Gone are the days when men\'s grooming was limited to a quick shave and haircut. Today, men are embracing comprehensive grooming routines as an essential part of self-care and confidence-building. Here\'s what\'s driving this trend:

**The Modern Man's Grooming Evolution:**
- **Skincare is In:** Men are increasingly recognizing the importance of proper skincare routines, including cleansing, moisturizing, and sun protection.
- **Beard Care Boom:** With the beard trend still going strong, specialized beard oils, balms, and grooming kits have become staples.
- **Professional Services:** More men are booking regular salon appointments for facials, hair treatments, and professional grooming services.

**Why This Matters:**
Studies show that regular grooming not only improves appearance but also boosts confidence and mental well-being. When you look good, you feel good!

**Finding the Right Professional:**
With Tressle, finding qualified grooming professionals has never been easier. Our platform connects you with top-rated barbers and grooming experts who understand modern men\'s grooming needs.

Ready to upgrade your grooming routine? Book an appointment with a Tressle professional today!''',
      author: 'Michael Chen',
      date: 'December 10, 2024',
      readTime: '6 min read',
      imageUrl:
          'https://images.unsplash.com/photo-1503951914875-452162b0f3f1?w=800',
      category: 'Men\'s Grooming',
    ),
    BlogPost(
      id: '3',
      title: 'How to Choose the Right Salon for Your Needs',
      content: '''
Finding the perfect salon can be overwhelming with so many options available. Whether you\'re looking for a simple haircut or a complete transformation, here\'s your guide to choosing the right salon:

**1. Identify Your Needs:**
Are you looking for specialized services like coloring, keratin treatment, or bridal makeup? Make a list of services you need before starting your search.

**2. Check Reviews and Ratings:**
Platforms like Tressle provide authentic reviews from real customers. Pay attention to consistent feedback about service quality, cleanliness, and customer service.

**3. Consider Location and Convenience:**
Choose a salon that\'s conveniently located and has flexible booking options. Tressle makes it easy to find salons near you with available time slots.

**4. Review Portfolios:**
Most professional salons showcase their work online. Look for before-and-after photos that match the style you\'re seeking.

**5. Hygiene and Safety Standards:**
In today\'s world, cleanliness is non-negotiable. Look for salons that follow proper sanitation protocols.

**6. Price vs. Value:**
While price is important, consider the value you\'re getting. Sometimes paying a bit more for expertise and quality products is worth it.

**7. Consultation First:**
Many salons offer free consultations. Use this opportunity to discuss your needs and gauge their professionalism.

**Why Tressle Helps:**
Tressle simplifies this process by providing detailed salon profiles, verified reviews, and easy booking options. Our platform ensures you have all the information needed to make an informed decision.

Start your journey to beautiful hair today by exploring Tressle\'s network of professional salons!''',
      author: 'Emma Rodriguez',
      date: 'December 5, 2024',
      readTime: '7 min read',
      imageUrl:
          'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=800',
      category: 'Tips & Advice',
    ),
    BlogPost(
      id: '4',
      title: 'Sustainable Beauty: Eco-Friendly Salon Practices',
      content: '''
As consumers become more environmentally conscious, the beauty industry is evolving to meet the demand for sustainable practices. Here\'s how modern salons are going green and how you can support eco-friendly beauty:

**Sustainable Salon Initiatives:**

1. **Chemical-Free Products:** Many salons now offer organic, vegan, and cruelty-free products that are better for both your hair and the environment.

2. **Water Conservation:** Eco-conscious salons install low-flow faucets and use water-saving techniques during services.

3. **Energy Efficiency:** LED lighting, energy-efficient appliances, and smart climate control systems help reduce carbon footprints.

4. **Waste Reduction:** From biodegradable capes to recycling programs for hair clippings and product containers, waste reduction is a priority.

5. **Digital Operations:** Paperless consultations, digital receipts, and online bookings reduce paper waste significantly.

**How to Identify Eco-Friendly Salons:**
- Look for certifications like Green Circle Salons or other environmental credentials
- Ask about their sustainability policies during consultations
- Check if they use refillable product containers
- Inquire about their recycling and waste management practices

**Tressle's Commitment:**
At Tressle, we\'re committed to promoting sustainable practices. Many of our partner salons have adopted eco-friendly measures, making it easier for you to make environmentally responsible choices.

**Your Role as a Consumer:**
You can support sustainable beauty by:
- Choosing salons with green practices
- Opting for digital receipts and appointments
- Bringing your own reusable water bottle
- Supporting brands with eco-friendly packaging

Together, we can make beauty more sustainable. Book your next appointment with an eco-friendly salon through Tressle!''',
      author: 'David Park',
      date: 'November 28, 2024',
      readTime: '8 min read',
      imageUrl:
          'https://images.unsplash.com/photo-1519415387722-a1c3bbef716c?w=800',
      category: 'Sustainability',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Blogs & Articles'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // Implement search functionality
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: blogPosts.length,
        itemBuilder: (context, index) {
          return BlogPostCard(blogPost: blogPosts[index]);
        },
      ),
    );
  }
}

class BlogPost {
  final String id;
  final String title;
  final String content;
  final String author;
  final String date;
  final String readTime;
  final String imageUrl;
  final String category;

  BlogPost({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.date,
    required this.readTime,
    required this.imageUrl,
    required this.category,
  });
}

class BlogPostCard extends StatelessWidget {
  final BlogPost blogPost;

  BlogPostCard({required this.blogPost});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlogDetailScreen(blogPost: blogPost),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured Image from Network
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Image.network(
                blogPost.imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 180,
                    width: double.infinity,
                    color: Color(0xFF00A693).withOpacity(0.1),
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF00A693),
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 180,
                    width: double.infinity,
                    color: Color(0xFF00A693).withOpacity(0.1),
                    child: Center(
                      child: Icon(
                        Icons.article,
                        size: 60,
                        color: Color(0xFF00A693).withOpacity(0.3),
                      ),
                    ),
                  );
                },
              ),
            ),

            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFF00A693).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      blogPost.category,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF00A693),
                      ),
                    ),
                  ),

                  SizedBox(height: 12),

                  // Title
                  Text(
                    blogPost.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 12),

                  // Meta Info
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 4),
                      Text(
                        blogPost.author,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      SizedBox(width: 16),
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 4),
                      Text(
                        blogPost.date,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),

                  SizedBox(height: 8),

                  // Read Time
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      SizedBox(width: 4),
                      Text(
                        blogPost.readTime,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Read More Button
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                BlogDetailScreen(blogPost: blogPost),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        backgroundColor: Color(0xFF00A693).withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Read More',
                            style: TextStyle(
                              color: Color(0xFF00A693),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: Color(0xFF00A693),
                          ),
                        ],
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

class BlogDetailScreen extends StatelessWidget {
  final BlogPost blogPost;

  BlogDetailScreen({required this.blogPost});

  // Function to copy text to clipboard
  void _copyToClipboard(BuildContext context) {
    final textToCopy =
        '''
${blogPost.title}

${blogPost.content}

Author: ${blogPost.author}
Published: ${blogPost.date}
''';

    Clipboard.setData(ClipboardData(text: textToCopy)).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Article copied to clipboard!'),
            ],
          ),
          backgroundColor: Color(0xFF00A693),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    });
  }

  // Function to share article
  void _shareArticle() {
    final textToShare =
        '''
${blogPost.title}

${blogPost.content}

Author: ${blogPost.author}
Published: ${blogPost.date}

Read more on Tressle App
''';

    Share.share(textToShare, subject: blogPost.title);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Article'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured Image from Network
            Image.network(
              blogPost.imageUrl,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 250,
                  width: double.infinity,
                  color: Color(0xFF00A693).withOpacity(0.1),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF00A693),
                      ),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 250,
                  width: double.infinity,
                  color: Color(0xFF00A693).withOpacity(0.1),
                  child: Center(
                    child: Icon(
                      Icons.article,
                      size: 80,
                      color: Color(0xFF00A693).withOpacity(0.3),
                    ),
                  ),
                );
              },
            ),

            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFF00A693).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      blogPost.category,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF00A693),
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Title
                  Text(
                    blogPost.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(height: 16),

                  // Meta Info
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Color(0xFF00A693).withOpacity(0.1),
                        child: Icon(
                          Icons.person,
                          size: 16,
                          color: Color(0xFF00A693),
                        ),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            blogPost.author,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            blogPost.date,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                      Row(
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 4),
                          Text(
                            blogPost.readTime,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: 24),
                  Divider(),
                  SizedBox(height: 24),

                  // Content
                  Text(
                    blogPost.content,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.8,
                      color: Colors.grey[800],
                    ),
                  ),

                  SizedBox(height: 32),

                  // Share Section
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Share this article',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildShareButton(
                                icon: Icons.copy,
                                label: 'Copy',
                                color: Colors.grey[700]!,
                                onTap: () => _copyToClipboard(context),
                              ),
                              _buildShareButton(
                                icon: Icons.share,
                                label: 'Share',
                                color: Color(0xFF00A693),
                                onTap: _shareArticle,
                              ),
                            ],
                          ),
                        ],
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

  Widget _buildShareButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
