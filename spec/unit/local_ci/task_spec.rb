require "spec_helper"

describe LocalCI::Task do
  describe "#initialize" do
    context "with parallel preqresuites" do
      it "creates a MultiTask" do
        expect(::Rake::MultiTask).to receive(:[]).with("task")

        LocalCI::Task.new("task", parallel_prerequisites: true)
      end

      context "with a comment" do
        it "sets the comment" do
          task = double(:task)
          allow(::Rake::MultiTask).to receive(:[]).and_return(task)
          expect(task).to receive(:comment=).with("comment")

          LocalCI::Task.new("task", comment: "comment", parallel_prerequisites: true)
        end
      end

      context "without a comment" do
        it "does not set the comment" do
          task = double(:task)
          allow(::Rake::MultiTask).to receive(:[]).and_return(task)
          expect(task).not_to receive(:comment=)

          LocalCI::Task.new("task", parallel_prerequisites: true)
        end
      end
    end

    context "with sequential preqresuites" do
      it "creates a Task" do
        expect(::Rake::Task).to receive(:[]).with("task")

        LocalCI::Task.new("task", parallel_prerequisites: false)
      end

      context "with a comment" do
        it "sets the comment" do
          task = double(:task)
          allow(::Rake::Task).to receive(:[]).and_return(task)
          expect(task).to receive(:comment=).with("comment")

          LocalCI::Task.new("task", comment: "comment", parallel_prerequisites: false)
        end
      end

      context "without a comment" do
        it "does not set the comment" do
          task = double(:task)
          allow(::Rake::Task).to receive(:[]).and_return(task)
          expect(task).not_to receive(:comment=)

          LocalCI::Task.new("task", parallel_prerequisites: false)
        end
      end
    end
  end

  describe ".[]" do
    context "given a block" do
      before do
        @block = -> { puts :hi }
      end

      it "creates a LocalCI::Task" do
        LocalCI::Task["task", "comment", &@block]

        expect(Rake::Task.task_defined?("task")).to be(true)
      end

      it "defines the task" do
        task = double(:task)
        allow(LocalCI::Task).to receive(:new).and_return(task)
        expect(task).to receive(:define) do |&block|
          expect(block).to eq(@block)
        end

        LocalCI::Task["task", "comment", &@block]
      end
    end

    context "not given a block" do
      it "creates a LocalCI::Task" do
        expect(LocalCI::Task).to receive(:new).with(
          "task",
          comment: "comment"
        )

        LocalCI::Task["task", "comment"]
      end

      it "does not define the task" do
        task = double(:task)
        allow(LocalCI::Task).to receive(:new).and_return(task)
        expect(task).not_to receive(:define)

        LocalCI::Task["task", "comment"]
      end
    end
  end

  describe "#add_prerequisite" do
    before do
      @task = LocalCI::Task.new("task", parallel_prerequisites: true)
    end

    it "adds the prerequisite" do
      expect(@task.prerequisites).to receive(:<<).with("prereq")

      @task.add_prerequisite("prereq")
    end

    context "When it already has that prerequisite" do
      it "doesn't add it again" do
        expect(@task.prerequisites).not_to receive(:<<)
        expect(@task).to receive(:prerequisites).and_return(["prereq"])

        @task.add_prerequisite("prereq")
      end
    end
  end

  describe "#define" do
    before do
      @task = LocalCI::Task.new("task", parallel_prerequisites: true)
    end

    it "calls define_task" do
      expect(::Rake::Task).to receive(:define_task).with("task")

      @task.define {}
    end

    it "uses the passed in block as the task body" do
      @block_run = false

      @task.define { @block_run = true }

      @task.invoke
      expect(@block_run).to be(true)
    end
  end
end
