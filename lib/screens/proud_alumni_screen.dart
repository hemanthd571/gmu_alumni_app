import 'package:flutter/material.dart';
import '../config/app_config.dart';

class ProudAlumniScreen extends StatelessWidget {
  const ProudAlumniScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> proudAlumni = [
      {
        'name': 'Virupaksha Gupta',
        'image': 'assets/images/proud/VIRUPAKSHA GUPTA.jpeg',
        'batch': 'Output',
        'info': 'AI Engineer at Microsoft with expertise in LLMs, Azure, and Agentic AI. Previously worked at Daimler Trucks, bringing extensive experience in artificial intelligence and machine learning. Winner of Analytica_25 and Smart India Hackathon 2022, and secured silver medal at LatentView ML Hackathon. A 3× NPTEL Topper demonstrating exceptional academic excellence. Specializes in Python programming, Large Language Models, Azure cloud services, and cutting-edge Agentic AI technologies. Passionate about leveraging AI to solve complex real-world problems and drive innovation in the tech industry.',
      },
      {
        'name': 'Dr. Manjunatha Thondamal',
        'image': 'assets/images/proud/Manjunath.png',
        'batch': '2006 Output',
        'info': 'Manjunatha Thondamal is an Associate Professor at Department of Biotechnology, GST. He received his Ph.D. from the ENS de Lyon, France in 2014. He was a postdoctoral research associate at University of Rochester, NY USA. Before joining GITAM, he served as DST INSPIRE Faculty at DRILS Hyderabad and at SRM University AP. He is a visiting scientist at Institute Pasteur, Paris. His research group at GITAM mainly focuses on the genetics of aging using C. elegans as model system.',
      },
      {
        'name': 'Dr. Anshu Alok',
        'image': 'assets/images/proud/Anshu.png',
        'batch': '2009 Output',
        'info': 'Anshu Alok is a postdoctoral researcher at the University of Minnesota, USA, working in plant molecular biology and biotechnology. His research focuses on CRISPR-based genome editing tools like Cas9 and Cpf1 to improve crop resilience and genetic engineering methods. He has published over 90 papers, with more than 2,300 citations and 21,000 reads on ResearchGate. His contributions include advances in soybean transformation, gene regulation, and plant stress response studies. He also serves in editorial roles for journals such as BMC Plant Methods and Frontiers in Genome Editing. Through his work, he is driving innovations in sustainable agriculture and crop improvement.',
      },
      {
        'name': 'Milind DM',
        'image': 'assets/images/proud/Milind.png',
        'batch': '2020 Output',
        'info': 'Pursued his passion for science with a BE Biotechnology, a fusion of all sciences. Currently working in Biocon Biologics Ltd as an executive in the upstream production department for PEG-GCSF. Worked in Shilpa Biologicals Private ltd, Dharwad as a trainee in production department in microbial fermentation upstream process for Recombinant Human Albumin & Zycov-D corona vaccine. Worked as student intern in Karnataka Antibiotics and Pharmaceuticals limited, Banglore.',
      },
      {
        'name': 'Sindhu S Patil',
        'image': 'assets/images/proud/sindhu.png',
        'batch': '2016 Output',
        'info': 'Dedicated Advocate enrolled with the Karnataka State Bar council, adept in communication and administration. Skilled in trademark drafting and prosecution across India and the US. Proficient in conducting IP searches and ensuring compliance. Expert in managing prosecution proceedings and client IP profiles with meticulous attention to deadlines. Actively contributes to idea generation and innovation. Experienced in attending arbitration hearings and drafting legal contracts. Interned with various legal offices during LLB and LLM studies. Specialized in Intellectual Property Rights, Corporate Law, Criminal Law, Legal Research, and Drafting. Passionate about leveraging legal expertise to serve clients effectively and uphold justice.',
      },
      {
        'name': 'Prajwal Nayak',
        'image': '',
        'batch': '2006 Output Batch',
        'info': 'Currently working as Director, software delivery lead Global Disputes at VISA. He also worked in Deutsche Bank Singapore for Three years as Technical specialist and software Engineer in HCL Technologist. He a seasoned technology leader with a knack for driving innovation and performance in the realms of GenAI, enterprise systems and big data. Leading high-performing teams, He specialize in designing and delivering scalable. Performance – optimized solutions that power business success. He expertise spans: Architecting Enterprise system, Big data & Analytics, Performance & Security, Distributed systems.',
      },
      {
        'name': 'Uday V Harihar',
        'image': '',
        'batch': '2012 Output Batch',
        'info': 'Currently working as Tech Lead at Resideo in Honewell Home. Experienced Android native App Developer and Flutter for cross platform with a demonstrated history of working in Home Automation and Security system services industry. Skilled in Android. Has projected his academic excellence in being second person out of selected 1500 people and recently elevated as senior developer. He Won Runner-up award in Hackathon-15.',
      },
      {
        'name': 'Shreeganesha G J',
        'image': '',
        'batch': '2020 Output Batch',
        'info': "Passionate Software Engineer currently working as a Senior Software Engineer at Target Corporation, specializing in the design and development of P1 (mission-critical) backend applications that drive Target's large-scale retail systems. Adept at building highly scalable, resilient, and efficient distributed systems ensuring business continuity and performance at scale. Began professional journey with Subex, gaining a strong foundation in backend engineering and product development. Recognized for his problem-solving mindset, leadership, and dedication to continuous learning. Passionate about leveraging technology to create reliable systems that impact millions of users every day.",
      },
      {
        'name': 'Krushi D',
        'image': '',
        'batch': '2022 Output Batch',
        'info': 'Software Engineer at Ernst & Young, specializing in developing and enhancing web applications using React. Experienced in building responsive, efficient, and user-focused interfaces that support business growth and client satisfaction. Started and continuing career with Ernst & Young, gaining strong skills in frontend architecture, component-based development, and cross-functional collaboration. Committed to continuous learning and using modern technologies to deliver reliable and high-quality web solutions.',
      },
      {
        'name': 'Sheetal S V',
        'image': '',
        'batch': '2023 Output Batch',
        'info': 'A passionate cyber security professional at Mercedes-Benz R&D, India, Specializing in PAMSM, PM Tools, IAM, SecOps. She is committed to safeguarding data and continuously learning to deepen her knowledge and skill in cybersecurity. She has received the Bronze award from Mercedes-Benz R&D India.',
      },
      {
        'name': 'Praveen D',
        'image': '',
        'batch': '2024 Output Batch',
        'info': 'Praveen D serves as an Assistant Manager at LXL Ideas, Bengaluru, contributing to digital learning platforms such as School Cinema, WACE, and SCIFF. He focuses on integrating Artificial Intelligence, Agentic AI, and software innovation to enhance the future of learning through technology. With expertise in product strategy, generative AI, and full-stack development, Actively involved in the startup ecosystem, Praveen brings an entrepreneurial approach to digital transformation. A graduate in Computer Science Engineering from GM Institute of Technology, Davangere.',
      },
    ];

    return Scaffold(
      backgroundColor: AppConfig.bgLight,
      appBar: AppBar(
        title: const Text('Hall of Fame'),
        centerTitle: true,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
              decoration: const BoxDecoration(
                color: AppConfig.primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: const Column(
                children: [
                  Icon(Icons.stars_rounded, color: AppConfig.secondaryColor, size: 40),
                  SizedBox(height: 12),
                  Text(
                    'Our Proud Alumni',
                    style: TextStyle(
                      color: AppConfig.secondaryColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Celebrating global impact and professional excellence',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return _buildAlumniListCard(context, proudAlumni[index]);
                },
                childCount: proudAlumni.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlumniListCard(BuildContext context, Map<String, String> alumni) {
    final bool hasImage = alumni['image']!.isNotEmpty;
    final bool isVirupaksha = alumni['name'] == 'Virupaksha Gupta';

    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Image Section (Landscape Card)
            if (hasImage)
              Container(
                width: 140, // Fixed width for the landscape side
                decoration: BoxDecoration(
                  color: isVirupaksha ? Colors.grey[50] : Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                  ),
                  child: Image.asset(
                    alumni['image']!,
                    fit: isVirupaksha ? BoxFit.contain : BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                  ),
                ),
              )
            else
              Container(
                width: 140,
                decoration: BoxDecoration(
                  color: AppConfig.primaryColor.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                  ),
                ),
                child: Center(
                  child: Icon(Icons.account_circle_rounded, 
                             size: 60, color: AppConfig.primaryColor.withOpacity(0.2)),
                ),
              ),

            // Right Info Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      alumni['name']!,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppConfig.primaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppConfig.secondaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        alumni['batch']!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppConfig.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.person, size: 50, color: Colors.grey),
    );
  }
}


