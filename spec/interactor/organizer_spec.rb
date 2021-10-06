require 'byebug'

module Interactor
  describe Organizer do
    include_examples :lint
    class Interactor2; end
    class Interactor3; end
    class Interactor4; end

    let(:organizer) { Class.new.send(:include, Organizer) }

    describe ".organize" do
      let(:interactor2) { Interactor2 }
      let(:interactor3) { Interactor3 }

      it "sets interactors given class arguments" do
        organizer.organize(interactor2, interactor3)
        expect(organizer.organized.collection.map(&:interactor_class))
          .to eql([Interactor::Interactor2, Interactor::Interactor3])
      end

      it "sets interactors given an array of classes" do
        organizer.organize([interactor2, interactor3])
        expect(organizer.organized.collection.map(&:interactor_class))
          .to eql([Interactor::Interactor2, Interactor::Interactor3])
      end

      it "accepts a block" do
        organizer.organize do
          run Interactor2
          run Interactor3
        end
        expect(organizer.organized.collection.map(&:interactor_class))
          .to eql([Interactor::Interactor2, Interactor::Interactor3])
      end
    end

    describe ".organized" do
      it "is empty by default" do
        expect(organizer.organized.collection).to eq([])
      end
    end

    describe "#call" do
      let(:instance) { organizer.new }
      let(:context) { double(:context) }
      let(:interactor2) { Interactor2 }
      let(:interactor3) { Interactor3 }
      let(:interactor4) { Interactor4 }

      context "without filtered interactors" do
        before do
          allow(instance).to receive(:context) { context }
          allow(organizer).to receive(:organized) {
            [interactor2, interactor3, interactor4]
          }
        end

        it "calls each interactor in order with the context" do
          expect(interactor2).to receive(:call!).once.with(instance, context).ordered
          expect(interactor3).to receive(:call!).once.with(instance, context).ordered
          expect(interactor4).to receive(:call!).once.with(instance, context).ordered

          instance.call
        end
      end

      context "with interactors filtered by a proc" do
        before do
          allow(instance).to receive(:context) { context }
          organizer.organize do
            run Interactor2
            run Interactor3, if: -> { false }
            run Interactor4
          end
        end

        it "calls each interactor in order with the context" do
          expect(Interactor2).to receive(:call!).once.with(context).ordered
          expect(Interactor3).to_not receive(:call!)
          expect(Interactor4).to receive(:call!).once.with(context).ordered

          instance.call
        end
      end

      context "with interactors filtered by a method symbol" do
        before do
          def instance.should_run_interactor_3?; false; end
          allow(instance).to receive(:context) { context }
          organizer.organize do
            run Interactor2
            run Interactor3, if: :should_run_interactor_3?
            run Interactor4
          end
        end

        it "calls each interactor in order with the context" do
          expect(Interactor2).to receive(:call!).once.with(context).ordered
          expect(Interactor3).to_not receive(:call!)
          expect(Interactor4).to receive(:call!).once.with(context).ordered

          instance.call
        end
      end
    end
  end
end
