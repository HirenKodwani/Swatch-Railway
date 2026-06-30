class DepotDatabase {
  static final Map<String, Map<String, List<String>>> zoneData = {
    'Central Railway (CR)': {
      'Mumbai': ['Mumbai CSMT', 'Wadi Bunder', 'Kurla', 'Sanpada', 'Kalyan'],
      'Bhusawal': ['Bhusawal', 'Manmad', 'Jalgaon'],
      'Nagpur': ['Nagpur', 'Ajni'],
      'Pune': ['Pune', 'Daund'],
      'Solapur': ['Solapur', 'Wadi'],
    },
    'Eastern Railway (ER)': {
      'Howrah': ['Howrah', 'Liluah'],
      'Sealdah': ['Sealdah', 'Narkeldanga', 'Sonarpur'],
      'Asansol': ['Asansol'],
      'Malda': ['Malda Town'],
    },
    'Northern Railway (NR)': {
      'Delhi': ['Delhi', 'Shakurbasti', 'Ghaziabad'],
      'Lucknow (NR)': ['Lucknow Charbagh', 'Alambagh'],
      'Ambala': ['Ambala', 'Kalka'],
      'Moradabad': ['Moradabad', 'Bareilly'],
      'Firozpur': ['Firozpur', 'Jammu Tawi'],
    },
    'North Central Railway (NCR)': {
      'Prayagraj': ['Allahabad', 'Subedarganj'],
      'Agra': ['Agra Cantt'],
      'Jhansi': ['Jhansi'],
    },
    'North Eastern Railway (NER)': {
      'Gorakhpur': ['Gorakhpur', 'Gonda'],
      'Izzatnagar': ['Izzatnagar', 'Lalkuan'],
      'Lucknow (NER)': ['Badshahnagar'],
      'Varanasi': ['Varanasi'],
    },
    'Northeast Frontier Railway (NFR)': {
      'Katihar': ['Katihar'],
      'Alipurduar': ['Alipurduar Jn'],
      'Lumding': ['Lumding'],
      'Rangiya': ['Rangiya'],
      'Tinsukia': ['Tinsukia'],
    },
    'North Western Railway (NWR)': {
      'Jaipur': ['Jaipur'],
      'Ajmer': ['Ajmer'],
      'Bikaner': ['Bikaner'],
      'Jodhpur': ['Jodhpur'],
    },
    'Southern Railway (SR)': {
      'Chennai': ['Chennai Egmore', 'Tambaram', 'Basin Bridge'],
      'Madurai': ['Madurai'],
      'Salem': ['Salem'],
      'Palakkad': ['Palakkad'],
      'Thiruvananthapuram': ['Thiruvananthapuram'],
      'Tiruchirappalli': ['Tiruchirappalli'],
    },
    'South Central Railway (SCR)': {
      'Secunderabad': ['Secunderabad', 'Kacheguda'],
      'Hyderabad': ['Hyderabad'],
      'Guntakal': ['Guntakal'],
      'Guntur': ['Guntur'],
      'Nanded': ['Nanded'],
      'Vijayawada': ['Vijayawada'],
    },
    'South Eastern Railway (SER)': {
      'Kharagpur': ['Kharagpur'],
      'Adra': ['Adra'],
      'Chakradharpur': ['Chakradharpur'],
      'Ranchi': ['Ranchi'],
    },
    'South East Central Railway (SECR)': {
      'Bilaspur': ['Bilaspur'],
      'Raipur': ['Raipur'],
      'Nagpur (SECR)': ['Nagpur SECR'],
    },
    'South Western Railway (SWR)': {
      'Hubballi': ['Hubballi'],
      'Bengaluru': ['Bengaluru', 'Baiyappanahalli'],
      'Mysuru': ['Mysuru'],
    },
    'Western Railway (WR)': {
      'Mumbai': ['Mumbai Central'],
      'Ahmedabad': ['Ahmedabad', 'Sabarmati'],
      'Vadodara': ['Vadodara'],
      'Rajkot': ['Rajkot'],
      'Bhavnagar': ['Bhavnagar'],
      'Ratlam': ['Ratlam'],
    },
    'West Central Railway (WCR)': {
      'Jabalpur': ['Jabalpur'],
      'Bhopal': ['Bhopal'],
      'Kota': ['Kota'],
    },
    'East Central Railway (ECR)': {
      'Hajipur': ['Hajipur'],
      'Danapur': ['Danapur'],
      'Dhanbad': ['Dhanbad'],
      'Samastipur': ['Samastipur'],
      'Sonpur': ['Sonpur'],
    },
    'East Coast Railway (ECoR)': {
      'Bhubaneswar': ['Bhubaneswar'],
      'Khurda Road': ['Khurda Road'],
      'Sambalpur': ['Sambalpur'],
      'Waltair': ['Waltair (Vizag)'],
    },
    'Metro Railway Kolkata (MTP)': {
      'Kolkata': ['Noapara (Centralized Depot)'],
    },
  };
}
