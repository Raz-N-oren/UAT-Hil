public class JSON2ApexSuggestion {
 
    public class Matched_substrings {
        public Integer length;
        public Integer offset;
    }
 
    public List<Predictions> predictions;
    public String status;
 
    public class Predictions {
        public String description;
        public String id;
        public List<Matched_substrings> matched_substrings;
        public String place_id;
        public String reference;
        public Structured_formatting structured_formatting;
        public List<Terms> terms;
        public List<String> types;
    }
 
    public class Terms {
        public Integer offset;
        public String value;
    }
 
    public class Structured_formatting {
        public String main_text;
        public List<Matched_substrings> main_text_matched_substrings;
        public String secondary_text;
        public List<Matched_substrings> secondary_text_matched_substrings;
    }
}