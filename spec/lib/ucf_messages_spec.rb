# frozen_string_literal: true

require 'ucf_messages'
require 'rails_helper'

describe UcfMessages do
  describe 'message' do
    let(:response) { double('response') }
    let(:protocol) { double('protocol') }
    let(:protocol_subscription) { double('protocol_subscription') }
    let(:rewards) { [nil, double('reward')] }

    context 'without rewards' do
      before do
        allow(protocol).to receive(:calculate_reward).with(anything, false).and_return(0)
        allow(protocol).to receive(:calculate_reward).with(anything, true).and_return(1)
        allow(protocol).to receive(:rewards).and_return(rewards)
        allow(rewards.second).to receive(:threshold).and_return(3)
        allow(protocol_subscription).to receive(:protocol).and_return(protocol)
        allow(response).to receive(:protocol_subscription).and_return(protocol_subscription)
      end

      context 'first invitation' do
        it 'returns a specific message' do
          protocol_completion = [
            { completed: false, periodical: false, reward_points: 0, future: true, streak: 1 }
          ]
          expected_message = 'Welkom bij het u-can-feel dagboekonderzoek! Doe je ook mee? We vragen je om elke week ' \
                             'in een paar minuten wat vragen te beantwoorden over hoe het met je gaat. Daarmee help ' \
                             'je ons met ons onderzoek én kun je geld verdienen. Via de link kun je meer informatie ' \
                             'krijgen en de eerste vragenlijst invullen.'
          allow(protocol_subscription).to receive(:protocol_completion).and_return(protocol_completion)
          expect(described_class.message(response)).to eq expected_message
        end
      end

      context 'everything missed' do
        it 'returns a specific message' do
          protocol_completion = [
            { completed: false, periodical: true, reward_points: 0, future: false, streak: 0 },
            { completed: false, periodical: true, reward_points: 0, future: false, streak: 0 },
            { completed: false, periodical: true, reward_points: 0, future: true, streak: 1 }
          ]
          expected_message = 'Je bent nog niet gestart met het u-can-feel dagboekonderzoek, {{deze_student}}! Doe je ' \
                             'alsnog mee? We vragen je om elke week een paar minuten wat vragen te beantwoorden over ' \
                             'hoe het met je gaat. Daarmee help je ons met ons onderzoek én kun je geld verdienen. ' \
                             'Via de link kun je meer informatie krijgen en de eerste vragenlijst invullen.'
          allow(protocol_subscription).to receive(:protocol_completion).and_return(protocol_completion)
          expect(described_class.message(response)).to eq expected_message
        end
        it 'works for the second response' do
          protocol_completion = [
            { completed: false, periodical: true, reward_points: 0, future: false, streak: 0 },
            { completed: false, periodical: true, reward_points: 0, future: true, streak: 1 }
          ]
          expected_message = 'Je bent nog niet gestart met het u-can-feel dagboekonderzoek, {{deze_student}}! Doe je ' \
                             'alsnog mee? We vragen je om elke week een paar minuten wat vragen te beantwoorden over ' \
                             'hoe het met je gaat. Daarmee help je ons met ons onderzoek én kun je geld verdienen. ' \
                             'Via de link kun je meer informatie krijgen en de eerste vragenlijst invullen.'
          allow(protocol_subscription).to receive(:protocol_completion).and_return(protocol_completion)
          expect(described_class.message(response)).to eq expected_message
        end
      end

      context 'not everything missed' do
        let(:expected_set) do
          [
            'Je hebt ons al enorm geholpen met de vragenlijsten die je hebt ingevuld, {{deze_student}}. Wil je ons ' \
            'weer helpen én daarmee geld verdienen?',
            'Hoi {{deze_student}}, doe je deze week weer mee aan het u-can-feel onderzoek? Vul de vragenlijst in en ' \
            'verdien een euro.',
            'Hoi {{deze_student}}! Vul direct de volgende vragenlijst in. Het kost je maar een paar minuten en je helpt ' \
            'ons enorm!',
            'Doe je weer mee aan het u-can-feel onderzoek, {{deze_student}}? Daarmee help je ons enorm én verdien je geld.',
            'We hebben je al even gemist, {{deze_student}}! Help je deze week weer mee met het u-can-feel onderzoek? Het ' \
            'kost maar een paar minuten van je tijd. Je helpt ons en je school. En je verdient er zelf ook een euro mee.'
          ]
        end
        it 'returns a specific message' do
          protocol_completion = [
            { completed: true, periodical: true, reward_points: 0, future: false, streak: 1 },
            { completed: false, periodical: true, reward_points: 0, future: false, streak: 0 },
            { completed: false, periodical: true, reward_points: 0, future: false, streak: 0 },
            { completed: false, periodical: true, reward_points: 0, future: true, streak: 1 }
          ]
          allow(protocol_subscription).to receive(:protocol_completion).and_return(protocol_completion)
          expect(expected_set).to be_member(described_class.message(response))
        end
      end

      context 'missed only the last after a streak' do
        it 'returns a specific message' do
          protocol_completion = [
            { completed: true, periodical: true, reward_points: 0, future: false, streak: 1 },
            { completed: true, periodical: true, reward_points: 0, future: false, streak: 2 },
            { completed: true, periodical: true, reward_points: 0, future: false, streak: 3 },
            { completed: false, periodical: true, reward_points: 0, future: false, streak: 0 },
            { completed: false, periodical: true, reward_points: 0, future: true, streak: 1 }
          ]
          expected_message = 'Je was heel goed bezig met het u-can-feel onderzoek {{deze_student}}. Probeer je ' \
                             'opnieuw de bonus-streak te halen om extra geld te verdienen?'
          allow(protocol_subscription).to receive(:protocol_completion).and_return(protocol_completion)
          expect(described_class.message(response)).to eq expected_message
        end
        it 'works if we missed some at the start' do
          protocol_completion = [
            { completed: false, periodical: true, reward_points: 0, future: false, streak: 0 },
            { completed: true, periodical: true, reward_points: 0, future: false, streak: 1 },
            { completed: true, periodical: true, reward_points: 0, future: false, streak: 2 },
            { completed: true, periodical: true, reward_points: 0, future: false, streak: 3 },
            { completed: false, periodical: true, reward_points: 0, future: false, streak: 0 },
            { completed: false, periodical: true, reward_points: 0, future: true, streak: 1 }
          ]
          expected_message = 'Je was heel goed bezig met het u-can-feel onderzoek {{deze_student}}. Probeer je ' \
                             'opnieuw de bonus-streak te halen om extra geld te verdienen?'
          allow(protocol_subscription).to receive(:protocol_completion).and_return(protocol_completion)
          expect(described_class.message(response)).to eq expected_message
        end
      end

      context 'missed only the last not after a streak' do
        it 'returns a specific message' do
          protocol_completion = [
            { completed: true, periodical: true, reward_points: 0, future: false, streak: 1 },
            { completed: true, periodical: true, reward_points: 0, future: false, streak: 2 },
            { completed: false, periodical: true, reward_points: 0, future: false, streak: 0 },
            { completed: false, periodical: true, reward_points: 0, future: true, streak: 1 }
          ]
          expected_message = 'We hebben je gemist vorige week. Help je deze week weer mee met het u-can-feel ' \
                             'onderzoek? Het kost maar een paar minuten van je tijd. Je helpt ons en je school. Én ' \
                             'je verdient er een euro mee.'
          allow(protocol_subscription).to receive(:protocol_completion).and_return(protocol_completion)
          expect(described_class.message(response)).to eq expected_message
        end
        it 'works if we missed some at the start' do
          protocol_completion = [
            { completed: false, periodical: true, reward_points: 0, future: false, streak: 0 },
            { completed: true, periodical: true, reward_points: 0, future: false, streak: 1 },
            { completed: false, periodical: true, reward_points: 0, future: false, streak: 0 },
            { completed: false, periodical: true, reward_points: 0, future: true, streak: 1 }
          ]
          expected_message = 'We hebben je gemist vorige week. Help je deze week weer mee met het u-can-feel ' \
                             'onderzoek? Het kost maar een paar minuten van je tijd. Je helpt ons en je school. Én ' \
                             'je verdient er een euro mee.'
          allow(protocol_subscription).to receive(:protocol_completion).and_return(protocol_completion)
          expect(described_class.message(response)).to eq expected_message
        end
      end

      context 'recently rejoined after missing a single questionnaire' do
        it 'returns a specific message' do
          # Has to have some responses completed before the fall out otherwise it is not a "rejoin"
          protocol_completion = [
            { completed: true, periodical: true, reward_points: 0, future: false, streak: 1 },
            { completed: false, periodical: true, reward_points: 0, future: false, streak: 0 },
            { completed: true, periodical: true, reward_points: 0, future: false, streak: 1 },
            { completed: false, periodical: true, reward_points: 0, future: true, streak: 2 }
          ]
          expected_message = 'Na een weekje rust ben je er sinds vorige week weer bij. Heel fijn dat je weer mee doet met het u-can-feel ' \
                             'onderzoek! Daarmee help je ons enorm. Vul je direct de volgende vragenlijst in?'
          allow(protocol_subscription).to receive(:protocol_completion).and_return(protocol_completion)
          expect(described_class.message(response)).to eq expected_message
        end
        it 'works if we missed some at the start' do
          protocol_completion = [
            { completed: true, periodical: true, reward_points: 0, future: false, streak: 1 },
            { completed: true, periodical: true, reward_points: 0, future: false, streak: 2 },
            { completed: true, periodical: true, reward_points: 0, future: false, streak: 3 },
            { completed: false, periodical: true, reward_points: 0, future: false, streak: 0 },
            { completed: true, periodical: true, reward_points: 0, future: false, streak: 1 },
            { completed: false, periodical: true, reward_points: 0, future: true, streak: 2 }
          ]
          expected_message = 'Na een weekje rust ben je er sinds vorige week weer bij. Heel fijn dat je weer mee doet met het u-can-feel ' \
                             'onderzoek! Daarmee help je ons enorm. Vul je direct de volgende vragenlijst in?'
          allow(protocol_subscription).to receive(:protocol_completion).and_return(protocol_completion)
          expect(described_class.message(response)).to eq expected_message
        end
      end

      context 'recently rejoined after missing multiple questionnaires' do
        it 'returns a specific message' do
          # Has to have some responses completed before the fall out otherwise it is not a "rejoin"
          protocol_completion = [
            { completed: true, periodical: true, reward_points: 0, future: false, streak: 1 },
            { completed: false, periodical: true, reward_points: 0, future: false, streak: 0 },
            { completed: false, periodical: true, reward_points: 0, future: false, streak: 0 },
            { completed: true, periodical: true, reward_points: 0, future: false, streak: 1 },
            { completed: false, periodical: true, reward_points: 0, future: true, streak: 2 }
          ]
          expected_message = 'Sinds vorige week doe je weer mee aan het u-can-feel onderzoek! Super! Vul nog twee ' \
                             'vragenlijsten in en je krijgt een bonus!'
          allow(protocol_subscription).to receive(:protocol_completion).and_return(protocol_completion)
          expect(described_class.message(response)).to eq expected_message
        end
        it 'works if we missed some at the start' do
          protocol_completion = [
            { completed: true, periodical: true, reward_points: 0, future: false, streak: 1 },
            { completed: true, periodical: true, reward_points: 0, future: false, streak: 2 },
            { completed: true, periodical: true, reward_points: 0, future: false, streak: 3 },
            { completed: false, periodical: true, reward_points: 0, future: false, streak: 0 },
            { completed: false, periodical: true, reward_points: 0, future: false, streak: 0 },
            { completed: false, periodical: true, reward_points: 0, future: false, streak: 0 },
            { completed: true, periodical: true, reward_points: 0, future: false, streak: 1 },
            { completed: false, periodical: true, reward_points: 0, future: true, streak: 2 }
          ]
          expected_message = 'Sinds vorige week doe je weer mee aan het u-can-feel onderzoek! Super! Vul nog twee ' \
                             'vragenlijsten in en je krijgt een bonus!'
          allow(protocol_subscription).to receive(:protocol_completion).and_return(protocol_completion)
          expect(described_class.message(response)).to eq expected_message
        end
      end

      context 'about to be on streak' do
        it 'returns a specific message' do
          protocol_completion = [
            { completed: true, periodical: true, reward_points: 0, future: false, streak: 1 },
            { completed: true, periodical: true, reward_points: 0, future: false, streak: 2 },
            { completed: false, periodical: true, reward_points: 0, future: true, streak: 3 }
          ]
          expected_message = 'Je bent goed bezig {{deze_student}}! Vul deze vragenlijst in en bereik een bonus-streak! Je verdient dan ' \
                             'elke week 50% meer!'
          allow(protocol_subscription).to receive(:protocol_completion).and_return(protocol_completion)
          expect(described_class.message(response)).to eq expected_message
        end
        it 'works with some missed responses' do
          protocol_completion = [
            { completed: false, periodical: true, reward_points: 0, future: false, streak: 0 },
            { completed: false, periodical: true, reward_points: 0, future: false, streak: 0 },
            { completed: true, periodical: true, reward_points: 0, future: false, streak: 1 },
            { completed: true, periodical: true, reward_points: 0, future: false, streak: 2 },
            { completed: false, periodical: true, reward_points: 0, future: true, streak: 3 }
          ]
          expected_message = 'Je bent goed bezig {{deze_student}}! Vul deze vragenlijst in en bereik een bonus-streak! Je verdient dan ' \
                             'elke week 50% meer!'
          allow(protocol_subscription).to receive(:protocol_completion).and_return(protocol_completion)
          expect(described_class.message(response)).to eq expected_message
        end
      end

      context 'already on a streak' do
        let(:expected_set) do
          [
            'Fijn dat je zo behulpzaam bent, {{deze_student}}! Vul je opnieuw de vragenlijst in?',
            'Je zit nog steeds in je bonus-streak! Je u-can-feel spaarpotje raakt al behoorlijk vol ;) Vul direct de ' \
            'vragenlijst in om je bonus-streak te behouden.',
            'Bedankt voor je inzet! Ga zo door :D Er staat weer een nieuwe vragenlijst voor je klaar.',
            '{{deze_student}}, je bent een topper! Bedankt voor je goede hulp! Vul je direct de vragenlijst weer in?',
            'Goed bezig met je bonus-streak, ga zo door!',
            'Super dat je de vragenlijst al zo vaak achter elkaar hebt ingevuld, bedankt en ga zo door!',
            'Hoi {{deze_student}}! Vul je de vragenlijst weer in om geld te verdienen?'
          ]
        end
        it 'returns a specific message' do
          protocol_completion = [
            { completed: true, periodical: true, reward_points: 0, future: false, streak: 1 },
            { completed: true, periodical: true, reward_points: 0, future: false, streak: 2 },
            { completed: true, periodical: true, reward_points: 0, future: false, streak: 3 },
            { completed: false, periodical: true, reward_points: 0, future: true, streak: 4 }
          ]
          allow(protocol_subscription).to receive(:protocol_completion).and_return(protocol_completion)
          expect(expected_set).to be_member(described_class.message(response))
        end
        it 'works with some missed responses' do
          protocol_completion = [
            { completed: false, periodical: true, reward_points: 0, future: false, streak: 0 },
            { completed: false, periodical: true, reward_points: 0, future: false, streak: 0 },
            { completed: true, periodical: true, reward_points: 0, future: false, streak: 1 },
            { completed: true, periodical: true, reward_points: 0, future: false, streak: 2 },
            { completed: true, periodical: true, reward_points: 0, future: false, streak: 3 },
            { completed: false, periodical: true, reward_points: 0, future: true, streak: 4 }
          ]
          allow(protocol_subscription).to receive(:protocol_completion).and_return(protocol_completion)
          expect(expected_set).to be_member(described_class.message(response))
        end
      end

      context 'not already on streak' do
        let(:expected_set) do
          [
            'Hoi {{deze_student}}! Er staat een vragenlijst voor je klaar, vul je hem weer in? :D',
            'Een u-can-feel tip: vul drie weken achter elkaar een vragenlijst in en verdien een bonus voor elke ' \
            'vragenlijst!',
            'Hoi {{deze_student}}! Vul direct de volgende vragenlijst in. Het kost je maar een paar minuten en je helpt ' \
            'ons enorm!',
            'Hallo {{deze_student}}, verdien een euro! Vul nu de vragenlijst in!',
            'Fijn dat jij meedoet! Vul je de vragenlijst weer in? Door jou kunnen leerlingen met wie het niet zo goed ' \
            'gaat nog betere begeleiding krijgen in de toekomst!',
            'Help {{je_school}} nog beter te worden in wat ze doen en vul nu de vragenlijst in!',
            'Heel fijn dat je meedoet! Vul je de vragenlijst weer in? Hiermee help je {{je_school}} om leerlingen nog ' \
            'beter te begeleiden!'
          ]
        end
        it 'returns a specific message' do
          protocol_completion = [
            { completed: true, periodical: true, reward_points: 0, future: false, streak: 1 },
            { completed: false, periodical: true, reward_points: 0, future: true, streak: 2 }
          ]
          allow(protocol_subscription).to receive(:protocol_completion).and_return(protocol_completion)
          expect(expected_set).to be_member(described_class.message(response))
        end
        it 'works with some missed responses' do
          protocol_completion = [
            { completed: false, periodical: true, reward_points: 0, future: false, streak: 0 },
            { completed: true, periodical: true, reward_points: 0, future: false, streak: 1 },
            { completed: false, periodical: true, reward_points: 0, future: true, streak: 2 }
          ]
          allow(protocol_subscription).to receive(:protocol_completion).and_return(protocol_completion)
          expect(expected_set).to be_member(described_class.message(response))
        end
      end
    end

    context 'with rewards' do
      before do
        allow(protocol).to receive(:rewards).and_return(rewards)
        allow(rewards.second).to receive(:threshold).and_return(3)
        allow(protocol_subscription).to receive(:protocol).and_return(protocol)
        allow(response).to receive(:protocol_subscription).and_return(protocol_subscription)
      end

      context 'about to reach 10 euros' do
        it 'returns a certain message' do
          allow(protocol).to receive(:calculate_reward).with(anything, false).and_return(998)
          allow(protocol).to receive(:calculate_reward).with(anything, true).and_return(1000)
          protocol_completion = [
            { completed: true, periodical: true, reward_points: 999, future: false, streak: 1 },
            { completed: false, periodical: true, reward_points: 1, future: true, streak: 2 }
          ]
          expected_message = 'Whoop! Na deze vragenlijst heb je al €10 euro verdiend. Ga zo door!'
          allow(protocol_subscription).to receive(:protocol_completion).and_return(protocol_completion)
          expect(described_class.message(response)).to eq expected_message
        end
      end
      context 'about to reach 20 euros' do
        it 'returns a certain message' do
          allow(protocol).to receive(:calculate_reward).with(anything, false).and_return(998)
          allow(protocol).to receive(:calculate_reward).with(anything, true).and_return(2000)
          protocol_completion = [
            { completed: true, periodical: true, reward_points: 999, future: false, streak: 1 },
            { completed: false, periodical: true, reward_points: 1, future: true, streak: 2 }
          ]
          expected_message = 'Je gaat hard! Na deze vragenlijst heb je al €20 euro gespaard.'
          allow(protocol_subscription).to receive(:protocol_completion).and_return(protocol_completion)
          expect(described_class.message(response)).to eq expected_message
        end
      end
      context 'about to reach 30 euros' do
        it 'returns a certain message' do
          allow(protocol).to receive(:calculate_reward).with(anything, false).and_return(2500)
          allow(protocol).to receive(:calculate_reward).with(anything, true).and_return(3500)
          protocol_completion = [
            { completed: true, periodical: true, reward_points: 999, future: false, streak: 1 },
            { completed: false, periodical: true, reward_points: 1, future: true, streak: 2 }
          ]
          expected_message = 'De teller blijft lopen! Na deze vragenlijst passeer jij de €30 euro :D'
          allow(protocol_subscription).to receive(:protocol_completion).and_return(protocol_completion)
          expect(described_class.message(response)).to eq expected_message
        end
      end
      context 'about to reach 40 euros' do
        it 'returns a certain message' do
          allow(protocol).to receive(:calculate_reward).with(anything, false).and_return(2999)
          allow(protocol).to receive(:calculate_reward).with(anything, true).and_return(4012)
          protocol_completion = [
            { completed: true, periodical: true, reward_points: 999, future: false, streak: 1 },
            { completed: false, periodical: true, reward_points: 1, future: true, streak: 2 }
          ]
          expected_message = 'Geweldig, na deze vragenlijst heb je al 40 euro verdiend!'
          allow(protocol_subscription).to receive(:protocol_completion).and_return(protocol_completion)
          expect(described_class.message(response)).to eq expected_message
        end
      end
      context 'about to reach 50 euros' do
        it 'returns a certain message' do
          allow(protocol).to receive(:calculate_reward).with(anything, false).and_return(4555)
          allow(protocol).to receive(:calculate_reward).with(anything, true).and_return(6000)
          protocol_completion = [
            { completed: true, periodical: true, reward_points: 999, future: false, streak: 1 },
            { completed: false, periodical: true, reward_points: 1, future: true, streak: 2 }
          ]
          expected_message = 'Wat heb jij je ontzettend goed ingezet! Inmiddels heb je al bijna 50 euro verdiend! Vul snel de volgende ' \
                             'vragenlijst in.'
          allow(protocol_subscription).to receive(:protocol_completion).and_return(protocol_completion)
          expect(described_class.message(response)).to eq expected_message
        end
      end
    end
  end
end
