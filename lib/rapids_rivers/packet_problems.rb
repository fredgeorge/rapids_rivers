require 'json'

module RapidsRivers

  # Understands issues about a particular JSON-formatted Packet
  class PacketProblems

    def initialize(original_json)
      @json_string = original_json
      @informational_messages, @warnings, @errors, @severe_errors = [], [], [], []
    end

    def errors?
      @errors.any? || @severe_errors.any?
    end

    def messages?
      errors? || @warnings.any? || @informational_messages.any?
    end

    def information(explanation)
      @informational_messages << explanation
    end

    def warning(explanation)
      @warnings << explanation
    end

    def error(explanation)
      @errors << explanation
    end

    def severe_error(explanation)
      @severe_errors << explanation
    end

    def to_s
      return("No errors detected in JSON:\n\t" + @json_string) if !messages?
      results = "Errors and/or messages exist. Original JSON string is:\n\t"
      results += @json_string
      results += messages("Severe errors", @severe_errors)
      results += messages("Errors", @errors)
      results += messages("Warnings", @warnings)
      results += messages("Information", @informational_messages)
      results += "\n"
    end

    private

      def messages(label, messages)
        return "" if messages.empty?
        results = "\n"
        results += ' '*5
        results += label
        results += ": "
        results += messages.size.to_s
        results += "\n\t"
        results += messages.join("\n\t")
      end

  end

end
