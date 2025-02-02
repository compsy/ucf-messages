# frozen_string_literal: true

require 'activesupport_extensions'

class UcfMessages
  MAX_REWARD_THRESHOLD = 5000

  class << self
    def message(response)
      @protocol = response.protocol_subscription.protocol
      @protocol_completion = response.protocol_subscription.protocol_completion
      @curidx = current_index
      pooled_message
    end

    private

    # There are two rewards: the first one is the multiplication factor for regular responses.
    # The second one is the multiplication factor for the streak responses, of which the threshold
    # property determines the start of the streak.
    def streak_size
      @protocol&.rewards&.second&.threshold || 3
    end

    # rubocop:disable Metrics/PerceivedComplexity
    def pooled_message
      sms_pool = []

      # Is this the first invitation? (= are we sending an invite for the first response in the prot sub?)
      sms_pool += first_invitation_pool if first_invitation?
      sms_pool += missed_previous_response if missed_previous_response? && sms_pool.empty?
      sms_pool += rejoined_after_missing_some if rejoined_after_missing_some? && sms_pool.empty?
      sms_pool += threshold_conditions if sms_pool.empty?
      sms_pool += streak_conditions if sms_pool.empty?
      sms_pool += default_pool if sms_pool.empty?

      # Sample returns a random entry from the array
      sms_pool.sample
    end
    # rubocop:enable Metrics/PerceivedComplexity

    def threshold_conditions
      current_protocol_completion = truncated_protocol_completion
      rewards_before = @protocol.calculate_reward(current_protocol_completion, false)
      rewards_after = @protocol.calculate_reward(current_protocol_completion, true)

      sms_pool = []
      1000.step(MAX_REWARD_THRESHOLD, 1000) do |threshold|
        # 1000 = 10 euro
        # override the current sms_pool so we only get the message for the highest threshold reached
        sms_pool = rewards_threshold_pool(threshold) if rewards_before < threshold && rewards_after >= threshold
      end
      sms_pool
    end

    # rubocop:disable Metrics/MethodLength
    def rewards_threshold_pool(threshold)
      case threshold
      when 1000 # 10 euro
        [
          'Whoop! Na deze vragenlijst heb je al €10 euro verdiend. Ga zo door!'
        ]
      when 2000 # 20 euro
        [
          'Je gaat hard! Na deze vragenlijst heb je al €20 euro gespaard.'
        ]
      when 3000 # 30 euro
        [
          'De teller blijft lopen! Na deze vragenlijst passeer jij de €30 euro :D'
        ]
      when 4000 # 40 euro
        [
          'Geweldig, na deze vragenlijst heb je al 40 euro verdiend!'
        ]
      when 5000 # 50 euro
        [
          'Wat heb jij je ontzettend goed ingezet! Inmiddels heb je al bijna 50 euro verdiend! Vul snel de volgende ' \
          'vragenlijst in.'
        ]
      else
        []
      end
    end
    # rubocop:enable Metrics/MethodLength

    def streak_conditions
      sms_pool = []

      # Streak about to be 3
      sms_pool += about_to_be_on_streak_pool if @protocol_completion[@curidx][:streak] == streak_size

      # On bonus streak (== on streak > 3)
      sms_pool += on_streak_pool if @protocol_completion[@curidx][:streak] > streak_size && sms_pool.empty?

      sms_pool
    end

    def about_to_be_on_streak_pool
      [
        'Je bent goed bezig! Vul deze vragenlijst in en bereik een bonus-streak! Je verdient dan ' \
        'elke week 50% meer!'
      ]
    end

    def on_streak_pool
      [
        'Fijn dat je zo behulpzaam bent! Vul je opnieuw de vragenlijst in?',
        'Je zit nog steeds in je bonus-streak! Je u-can-feel spaarpotje raakt al behoorlijk vol ;) Vul direct de ' \
        'vragenlijst in om je bonus-streak te behouden.',
        'Bedankt voor je inzet! Ga zo door :D Er staat weer een nieuwe vragenlijst voor je klaar.',
        'Je bent een topper! Bedankt voor je goede hulp! Vul je direct de vragenlijst weer in?',
        'Goed bezig met je bonus-streak, ga zo door!',
        'Super dat je de vragenlijst al zo vaak achter elkaar hebt ingevuld, bedankt en ga zo door!',
        'Hoi! Vul je de vragenlijst weer in om geld te verdienen?'
      ]
    end

    def first_invitation_pool
      [
        'Welkom bij het u-can-feel dagboekonderzoek! Doe je ook mee? We vragen je om elke week in een paar ' \
        'minuten wat vragen te beantwoorden over hoe het met je gaat. Daarmee help je ons met ons onderzoek ' \
        'én kun je geld verdienen. Via de link kun je meer informatie krijgen en de eerste vragenlijst ' \
        'invullen.'
      ]
    end

    def default_pool
      [
        'Hoi! Er staat een vragenlijst voor je klaar, vul je hem weer in? :D',
        'Een u-can-feel tip: vul drie weken achter elkaar een vragenlijst in en verdien een bonus voor elke ' \
        'vragenlijst!',
        'Hoi! Vul direct de volgende vragenlijst in. Het kost je maar een paar minuten en je helpt ' \
        'ons enorm!',
        'Wil je een euro verdienen? Vul nu de vragenlijst in!',
        'Fijn dat jij meedoet! Vul je de vragenlijst weer in? Door jou kunnen leerlingen met wie het niet zo goed ' \
        'gaat nog betere begeleiding krijgen in de toekomst!',
        'Help je school nog beter te worden in wat ze doen en vul nu de vragenlijst in!',
        'Heel fijn dat je meedoet! Vul je de vragenlijst weer in? Hiermee help je je school om leerlingen nog ' \
        'beter te begeleiden!'
      ]
    end

    def not_everything_missed
      [
        'Je hebt ons al enorm geholpen met de vragenlijsten die je hebt ingevuld. Wil je ons ' \
        'weer helpen én daarmee geld verdienen?',
        'Hallo, doe je deze week weer mee aan het u-can-feel onderzoek? Vul de vragenlijst in en ' \
        'verdien een euro.',
        'Hoi! Vul direct de volgende vragenlijst in. Het kost je maar een paar minuten en je helpt ' \
        'ons enorm!',
        'Doe je weer mee aan het u-can-feel onderzoek? Daarmee help je ons enorm én verdien je geld.',
        'We hebben je al even gemist! Help je deze week weer mee met het u-can-feel onderzoek? Het ' \
        'kost maar een paar minuten van je tijd. Je helpt ons en je school. En je verdient er zelf ook een euro mee.'
      ]
    end

    def missed_everything
      [
        'Je bent nog niet gestart met het u-can-feel dagboekonderzoek! Doe je alsnog mee? We ' \
        'vragen je om elke week een paar minuten wat vragen te beantwoorden over hoe het met je gaat. Daarmee help ' \
        'je ons met ons onderzoek én kun je geld verdienen. Via de link kun je meer informatie krijgen en de eerste ' \
        'vragenlijst invullen.'
      ]
    end

    def missed_one_after_streak
      [
        'Je was heel goed bezig met het u-can-feel onderzoek. Probeer je opnieuw de bonus-streak ' \
        'te halen om extra geld te verdienen?'
      ]
    end

    def missed_one_not_after_streak
      [
        'We hebben je gemist vorige week. Help je deze week weer mee met het u-can-feel onderzoek? Het kost maar ' \
        'een paar minuten van je tijd. Je helpt ons en je school. Én je verdient er een euro mee.'
      ]
    end

    def rejoined_after_missing_one
      [
        'Na een weekje rust ben je er sinds vorige week weer bij. Heel fijn dat je weer mee doet met het u-can-feel ' \
        'onderzoek! Daarmee help je ons enorm. Vul je direct de volgende vragenlijst in?'
      ]
    end

    def rejoined_after_missing_multiple
      [
        'Sinds vorige week doe je weer mee aan het u-can-feel onderzoek! Super! Vul nog twee vragenlijsten in en je ' \
        'krijgt een bonus!'
      ]
    end

    def rejoined_after_missing_some
      sms_pool = []

      sms_pool += rejoined_after_missing_one if rejoined_after_missing_one?
      sms_pool += rejoined_after_missing_multiple if sms_pool.empty?

      sms_pool
    end

    def missed_previous_response
      sms_pool = []
      # [missed] only the last?
      sms_pool += missed_last_only if missed_last_only?
      sms_pool += missed_everything if missed_everything? && sms_pool.empty?
      sms_pool += not_everything_missed if sms_pool.empty?

      sms_pool
    end

    def missed_last_only
      sms_pool = []

      sms_pool += missed_one_after_streak if missed_one_after_streak?
      sms_pool += missed_one_not_after_streak if sms_pool.empty?

      sms_pool
    end

    def truncated_protocol_completion
      @protocol_completion[0..@curidx]
    end

    def current_index
      # -1 in case there are no other measurements
      @protocol_completion.find_index { |entry| entry[:future] } || -1
    end

    def first_invitation?
      @curidx.zero?
    end

    def missed_previous_response?
      # Minimal pattern: .C         (X = completed, C = current)
      #           index: 01
      @curidx.positive? &&
        !@protocol_completion[@curidx - 1][:completed]
    end

    def missed_last_only?
      # Minimal pattern: X.C         (X = completed, C = current)
      #           index: 012
      @curidx > 1 &&
        !@protocol_completion[@curidx - 1][:completed] &&
        @protocol_completion[@curidx - 2][:completed]
    end

    def missed_one_after_streak?
      # Minimal pattern: XXX.C         (X = completed, C = current)
      #           index: 01234
      @curidx > 2 && # only make sure that we can check the index at curidx-2.
        !@protocol_completion[@curidx - 1][:completed] &&
        @protocol_completion[@curidx - 2][:completed] &&
        @protocol_completion[@curidx - 2][:streak] >= streak_size
    end

    def missed_everything?
      # Minimal pattern: .C           (X = completed, C = current)
      #           index: 01
      @curidx.positive? &&
        @protocol_completion[0..(@curidx - 1)].pluck(:completed).none?
    end

    def rejoined_after_missing_one?
      # Minimal pattern: X.XC         (X = completed, C = current)
      #           index: 0123
      @curidx > 2 &&
        @protocol_completion[@curidx - 1][:completed] &&
        !@protocol_completion[@curidx - 2][:completed] &&
        @protocol_completion[@curidx - 3][:completed]
    end

    def rejoined_after_missing_some?
      # Minimal pattern: X.XC         (X = completed, C = current)
      #           index: 0123
      @curidx > 2 &&
        @protocol_completion[@curidx - 1][:completed] &&
        !@protocol_completion[@curidx - 2][:completed] &&
        @protocol_completion[0..(@curidx - 3)].pluck(:completed).any?
    end
  end
end
