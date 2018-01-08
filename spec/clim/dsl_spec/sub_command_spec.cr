require "../dsl_spec"

macro spec_for_sub_commands(spec_class_name, main_help_message, sub_command_name, spec_dsl_lines, spec_desc, sub_help_message, spec_cases_hash)
  {% for key, spec_case_hash in spec_cases_hash %}
    {% for spec_case, index in spec_case_hash %}
      {% class_name = (spec_class_name.stringify + key.stringify.camelcase + index.stringify).id %}
      # define dsl
      class {{class_name}} < Clim
        main_command
        run do |opts, args|
          check_opts_and_args({{main_help_message}}, {{spec_case}})
        end

        sub do
          command {{sub_command_name}}
          {% for spec_dsl_line, index in spec_dsl_lines %}
            {{spec_dsl_line.id}}
          {% end %}
          run do |opts, args|
            check_opts_and_args({{sub_help_message}}, {{spec_case}})
          end
        end
      end

      # spec
      describe {{spec_desc}} do
        describe "if dsl is [" + {{spec_dsl_lines.join(", ")}} + "]," do
          describe "if argv is " + {{spec_case["argv"].stringify}} + "," do
            {% if spec_case.keys.includes?("expect_opts".id) %}
              it "opts and args are given as arguments of run block." do
                {{class_name}}.start_main({{spec_case["argv"]}})
              end
            {% elsif spec_case.keys.includes?("exception_message".id) %}
              it "raises an Exception." do
                expect_raises(Exception, {{spec_case["exception_message"]}}) do
                  {{class_name}}.start_main({{spec_case["argv"]}})
                end
              end
            {% else %}
              it "display help." do
                io = IO::Memory.new
                {{class_name}}.start_main({{spec_case["argv"]}}, io)
                {% if key == "main_command_case" %}
                  io.to_s.should eq {{main_help_message}}
                {% elsif key == "sub_command_case" %}
                  io.to_s.should eq {{sub_help_message}}
                {% end %}
              end
            {% end %}
          end
        end
      end
    {% end %}
  {% end %}
end

spec_for_sub_commands(
  spec_class_name: SubCommandOnly,
  main_help_message: <<-HELP_MESSAGE

                       Command Line Interface Tool.

                       Usage:

                         main_command [options] [arguments]

                       Options:

                         --help                           Show this help.

                       Sub Commands:

                         sub_command   Command Line Interface Tool.


                     HELP_MESSAGE,
  sub_command_name: "sub_command",
  spec_dsl_lines: [] of String,
  spec_desc: "sub command only,",
  sub_help_message: <<-HELP_MESSAGE

                      Command Line Interface Tool.

                      Usage:

                        sub_command [options] [arguments]

                      Options:

                        --help                           Show this help.


                    HELP_MESSAGE,
  spec_cases_hash: {
    main_command_case: [
      {
        argv:        %w(),
        expect_opts: ReturnOptsType.new,
        expect_args: [] of String,
      },
      {
        argv:        %w(arg1),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1"],
      },
      {
        argv:        %w(arg1 arg2),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1", "arg2"],
      },
      {
        argv:        %w(arg1 arg2 arg3),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1", "arg2", "arg3"],
      },
      {
        argv:              %w(-h),
        exception_message: "Undefined option. \"-h\"",
      },
      {
        argv:              %w(--help -ignore-option),
        exception_message: "Undefined option. \"-ignore-option\"",
      },
      {
        argv:              %w(-ignore-option --help),
        exception_message: "Undefined option. \"-ignore-option\"",
      },
      {
        argv: %w(--help),
      },
      {
        argv: %w(--help ignore-arg),
      },
      {
        argv: %w(ignore-arg --help),
      },
    ],
    sub_command_case: [
      {
        argv:        %w(sub_command),
        expect_opts: ReturnOptsType.new,
        expect_args: [] of String,
      },
      {
        argv:        %w(sub_command arg1),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1"],
      },
      {
        argv:        %w(sub_command arg1 arg2),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1", "arg2"],
      },
      {
        argv:        %w(sub_command arg1 arg2 arg3),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1", "arg2", "arg3"],
      },
      {
        argv:              %w(sub_command --help -ignore-option),
        exception_message: "Undefined option. \"-ignore-option\"",
      },
      {
        argv:              %w(sub_command -ignore-option --help),
        exception_message: "Undefined option. \"-ignore-option\"",
      },
      {
        argv:              %w(sub_command -m),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv:              %w(sub_command --missing-option),
        exception_message: "Undefined option. \"--missing-option\"",
      },
      {
        argv:              %w(sub_command -m arg1),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv:              %w(sub_command arg1 -m),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv:              %w(sub_command -m -d),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv: %w(sub_command --help),
      },
      {
        argv: %w(sub_command --help ignore-arg),
      },
      {
        argv: %w(sub_command ignore-arg --help),
      },
    ],
  }
)

spec_for_sub_commands(
  spec_class_name: SubCommandWithDescAndUsage,
  main_help_message: <<-HELP_MESSAGE

                       Command Line Interface Tool.

                       Usage:

                         main_command [options] [arguments]

                       Options:

                         --help                           Show this help.

                       Sub Commands:

                         sub_command   Sub command with desc.


                     HELP_MESSAGE,
  sub_command_name: "sub_command",
  spec_dsl_lines: [
    "desc \"Sub command with desc.\"",
    "usage \"sub_command with usage [options] [arguments]\"",
  ],
  spec_desc: "sub command only,",
  sub_help_message: <<-HELP_MESSAGE

                      Sub command with desc.

                      Usage:

                        sub_command with usage [options] [arguments]

                      Options:

                        --help                           Show this help.


                    HELP_MESSAGE,
  spec_cases_hash: {
    main_command_case: [
      {
        argv:        %w(),
        expect_opts: ReturnOptsType.new,
        expect_args: [] of String,
      },
      {
        argv:        %w(arg1),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1"],
      },
      {
        argv:        %w(arg1 arg2),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1", "arg2"],
      },
      {
        argv:        %w(arg1 arg2 arg3),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1", "arg2", "arg3"],
      },
      {
        argv:              %w(-h),
        exception_message: "Undefined option. \"-h\"",
      },
      {
        argv:              %w(--help -ignore-option),
        exception_message: "Undefined option. \"-ignore-option\"",
      },
      {
        argv:              %w(-ignore-option --help),
        exception_message: "Undefined option. \"-ignore-option\"",
      },
      {
        argv: %w(--help),
      },
      {
        argv: %w(--help ignore-arg),
      },
      {
        argv: %w(ignore-arg --help),
      },
    ],
    sub_command_case: [
      {
        argv:        %w(sub_command),
        expect_opts: ReturnOptsType.new,
        expect_args: [] of String,
      },
      {
        argv:        %w(sub_command arg1),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1"],
      },
      {
        argv:        %w(sub_command arg1 arg2),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1", "arg2"],
      },
      {
        argv:        %w(sub_command arg1 arg2 arg3),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1", "arg2", "arg3"],
      },
      {
        argv:              %w(sub_command --help -ignore-option),
        exception_message: "Undefined option. \"-ignore-option\"",
      },
      {
        argv:              %w(sub_command -ignore-option --help),
        exception_message: "Undefined option. \"-ignore-option\"",
      },
      {
        argv:              %w(sub_command -m),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv:              %w(sub_command --missing-option),
        exception_message: "Undefined option. \"--missing-option\"",
      },
      {
        argv:              %w(sub_command -m arg1),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv:              %w(sub_command arg1 -m),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv:              %w(sub_command -m -d),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv: %w(sub_command --help),
      },
      {
        argv: %w(sub_command --help ignore-arg),
      },
      {
        argv: %w(sub_command ignore-arg --help),
      },
    ],
  }
)

macro spec_for_sub_sub_commands(spec_class_name, main_help_message, sub_command_name, sub_help_message, sub_sub_command_name, spec_dsl_lines, spec_desc, sub_sub_help_message, spec_cases_hash)
  {% for key, spec_case_hash in spec_cases_hash %}
    {% for spec_case, index in spec_case_hash %}
      {% class_name = (spec_class_name.stringify + key.stringify.camelcase + index.stringify).id %}
      # define dsl
      class {{class_name}} < Clim
        main_command
        run do |opts, args|
          check_opts_and_args({{main_help_message}}, {{spec_case}})
        end

        sub do
          command {{sub_command_name}}
          run do |opts, args|
            check_opts_and_args({{sub_help_message}}, {{spec_case}})
          end

          sub do
            command {{sub_sub_command_name}}
            {% for spec_dsl_line, index in spec_dsl_lines %}
              {{spec_dsl_line.id}}
            {% end %}
            run do |opts, args|
              check_opts_and_args({{sub_sub_help_message}}, {{spec_case}})
            end
          end
        end
      end

      # spec
      describe {{spec_desc}} do
        describe "if dsl is [" + {{spec_dsl_lines.join(", ")}} + "]," do
          describe "if argv is " + {{spec_case["argv"].stringify}} + "," do
            {% if spec_case.keys.includes?("expect_opts".id) %}
              it "opts and args are given as arguments of run block." do
                {{class_name}}.start_main({{spec_case["argv"]}})
              end
            {% elsif spec_case.keys.includes?("exception_message".id) %}
              it "raises an Exception." do
                expect_raises(Exception, {{spec_case["exception_message"]}}) do
                  {{class_name}}.start_main({{spec_case["argv"]}})
                end
              end
            {% else %}
              it "display help." do
                io = IO::Memory.new
                {{class_name}}.start_main({{spec_case["argv"]}}, io)
                {% if key == "main_command_case" %}
                  io.to_s.should eq {{main_help_message}}
                {% elsif key == "sub_command_case" %}
                  io.to_s.should eq {{sub_help_message}}
                {% elsif key == "sub_sub_command_case" %}
                  io.to_s.should eq {{sub_sub_help_message}}
                {% end %}
              end
            {% end %}
          end
        end
      end
    {% end %}
  {% end %}
end

spec_for_sub_sub_commands(
  spec_class_name: SubSubCommandOnly,
  main_help_message: <<-HELP_MESSAGE

                       Command Line Interface Tool.

                       Usage:

                         main_command [options] [arguments]

                       Options:

                         --help                           Show this help.

                       Sub Commands:

                         sub_command   Command Line Interface Tool.


                     HELP_MESSAGE,
  sub_command_name: "sub_command",
  sub_help_message: <<-HELP_MESSAGE

                      Command Line Interface Tool.

                      Usage:

                        sub_command [options] [arguments]

                      Options:

                        --help                           Show this help.

                      Sub Commands:

                        sub_sub_command   Command Line Interface Tool.


                    HELP_MESSAGE,
  sub_sub_command_name: "sub_sub_command",
  spec_dsl_lines: [] of String,
  spec_desc: "sub command only,",
  sub_sub_help_message: <<-HELP_MESSAGE

                          Command Line Interface Tool.

                          Usage:

                            sub_sub_command [options] [arguments]

                          Options:

                            --help                           Show this help.


                        HELP_MESSAGE,
  spec_cases_hash: {
    main_command_case: [
      {
        argv:        %w(),
        expect_opts: ReturnOptsType.new,
        expect_args: [] of String,
      },
      {
        argv:        %w(arg1),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1"],
      },
      {
        argv:        %w(arg1 arg2),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1", "arg2"],
      },
      {
        argv:        %w(arg1 arg2 arg3),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1", "arg2", "arg3"],
      },
      {
        argv:              %w(-h),
        exception_message: "Undefined option. \"-h\"",
      },
      {
        argv:              %w(--help -ignore-option),
        exception_message: "Undefined option. \"-ignore-option\"",
      },
      {
        argv:              %w(-ignore-option --help),
        exception_message: "Undefined option. \"-ignore-option\"",
      },
      {
        argv: %w(--help),
      },
      {
        argv: %w(--help ignore-arg),
      },
      {
        argv: %w(ignore-arg --help),
      },
    ],
    sub_command_case: [
      {
        argv:        %w(sub_command),
        expect_opts: ReturnOptsType.new,
        expect_args: [] of String,
      },
      {
        argv:        %w(sub_command arg1),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1"],
      },
      {
        argv:        %w(sub_command arg1 arg2),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1", "arg2"],
      },
      {
        argv:        %w(sub_command arg1 arg2 arg3),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1", "arg2", "arg3"],
      },
      {
        argv:              %w(sub_command --help -ignore-option),
        exception_message: "Undefined option. \"-ignore-option\"",
      },
      {
        argv:              %w(sub_command -ignore-option --help),
        exception_message: "Undefined option. \"-ignore-option\"",
      },
      {
        argv:              %w(sub_command -m),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv:              %w(sub_command --missing-option),
        exception_message: "Undefined option. \"--missing-option\"",
      },
      {
        argv:              %w(sub_command -m arg1),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv:              %w(sub_command arg1 -m),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv:              %w(sub_command -m -d),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv: %w(sub_command --help),
      },
      {
        argv: %w(sub_command --help ignore-arg),
      },
      {
        argv: %w(sub_command ignore-arg --help),
      },
    ],
    sub_sub_command_case: [
      {
        argv:        %w(sub_command sub_sub_command),
        expect_opts: ReturnOptsType.new,
        expect_args: [] of String,
      },
      {
        argv:        %w(sub_command sub_sub_command arg1),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1"],
      },
      {
        argv:        %w(sub_command sub_sub_command arg1 arg2),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1", "arg2"],
      },
      {
        argv:        %w(sub_command sub_sub_command arg1 arg2 arg3),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1", "arg2", "arg3"],
      },
      {
        argv:              %w(sub_command sub_sub_command --help -ignore-option),
        exception_message: "Undefined option. \"-ignore-option\"",
      },
      {
        argv:              %w(sub_command sub_sub_command -ignore-option --help),
        exception_message: "Undefined option. \"-ignore-option\"",
      },
      {
        argv:              %w(sub_command sub_sub_command -m),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv:              %w(sub_command sub_sub_command --missing-option),
        exception_message: "Undefined option. \"--missing-option\"",
      },
      {
        argv:              %w(sub_command sub_sub_command -m arg1),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv:              %w(sub_command sub_sub_command arg1 -m),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv:              %w(sub_command sub_sub_command -m -d),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv: %w(sub_command sub_sub_command --help),
      },
      {
        argv: %w(sub_command sub_sub_command --help ignore-arg),
      },
      {
        argv: %w(sub_command sub_sub_command ignore-arg --help),
      },
    ],
  }
)

macro spec_for_jump_over_sub_sub_command(spec_class_name, main_help_message, sub_command_name, sub_help_message, sub_sub_command_name, spec_dsl_lines, spec_desc, sub_sub_help_message, spec_cases_hash)
  {% for key, spec_case_hash in spec_cases_hash %}
    {% for spec_case, index in spec_case_hash %}
      {% class_name = (spec_class_name.stringify + key.stringify.camelcase + index.stringify).id %}
      # define dsl
      class {{class_name}} < Clim
        main_command
        run do |opts, args|
          check_opts_and_args({{main_help_message}}, {{spec_case}})
        end

        sub do
          command "sub_command"
          run do |opts, args|
          end

          sub do
            command {{sub_sub_command_name}}
            {% for spec_dsl_line, index in spec_dsl_lines %}
              {{spec_dsl_line.id}}
            {% end %}
            run do |opts, args|
              check_opts_and_args({{sub_sub_help_message}}, {{spec_case}})
            end
          end

          command {{sub_command_name}}
          run do |opts, args|
            check_opts_and_args({{sub_help_message}}, {{spec_case}})
          end

        end
      end

      # spec
      describe {{spec_desc}} do
        describe "if dsl is [" + {{spec_dsl_lines.join(", ")}} + "]," do
          describe "if argv is " + {{spec_case["argv"].stringify}} + "," do
            {% if spec_case.keys.includes?("expect_opts".id) %}
              it "opts and args are given as arguments of run block." do
                {{class_name}}.start_main({{spec_case["argv"]}})
              end
            {% elsif spec_case.keys.includes?("exception_message".id) %}
              it "raises an Exception." do
                expect_raises(Exception, {{spec_case["exception_message"]}}) do
                  {{class_name}}.start_main({{spec_case["argv"]}})
                end
              end
            {% else %}
              it "display help." do
                io = IO::Memory.new
                {{class_name}}.start_main({{spec_case["argv"]}}, io)
                {% if key == "main_command_case" %}
                  io.to_s.should eq {{main_help_message}}
                {% elsif key == "sub_command_case" %}
                  io.to_s.should eq {{sub_help_message}}
                {% elsif key == "sub_sub_command_case" %}
                  io.to_s.should eq {{sub_sub_help_message}}
                {% end %}
              end
            {% end %}
          end
        end
      end
    {% end %}
  {% end %}
end

spec_for_jump_over_sub_sub_command(
  spec_class_name: JumpOverSubSubCommand,
  main_help_message: <<-HELP_MESSAGE

                       Command Line Interface Tool.

                       Usage:

                         main_command [options] [arguments]

                       Options:

                         --help                           Show this help.

                       Sub Commands:

                         sub_command                 Command Line Interface Tool.
                         jump_over_sub_sub_command   Command Line Interface Tool.


                     HELP_MESSAGE,
  sub_command_name: "jump_over_sub_sub_command",
  sub_help_message: <<-HELP_MESSAGE

                      Command Line Interface Tool.

                      Usage:

                        jump_over_sub_sub_command [options] [arguments]

                      Options:

                        --help                           Show this help.


                    HELP_MESSAGE,
  sub_sub_command_name: "sub_sub_command",
  spec_dsl_lines: [] of String,
  spec_desc: "jump over sub_sub command,",
  sub_sub_help_message: <<-HELP_MESSAGE

                          Command Line Interface Tool.

                          Usage:

                            sub_sub_command [options] [arguments]

                          Options:

                            --help                           Show this help.


                        HELP_MESSAGE,
  spec_cases_hash: {
    main_command_case: [
      {
        argv:        %w(),
        expect_opts: ReturnOptsType.new,
        expect_args: [] of String,
      },
      {
        argv:        %w(arg1),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1"],
      },
      {
        argv:        %w(arg1 arg2),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1", "arg2"],
      },
      {
        argv:        %w(arg1 arg2 arg3),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1", "arg2", "arg3"],
      },
      {
        argv:              %w(-h),
        exception_message: "Undefined option. \"-h\"",
      },
      {
        argv:              %w(--help -ignore-option),
        exception_message: "Undefined option. \"-ignore-option\"",
      },
      {
        argv:              %w(-ignore-option --help),
        exception_message: "Undefined option. \"-ignore-option\"",
      },
      {
        argv: %w(--help),
      },
      {
        argv: %w(--help ignore-arg),
      },
      {
        argv: %w(ignore-arg --help),
      },
    ],
    sub_command_case: [
      {
        argv:        %w(jump_over_sub_sub_command),
        expect_opts: ReturnOptsType.new,
        expect_args: [] of String,
      },
      {
        argv:        %w(jump_over_sub_sub_command arg1),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1"],
      },
      {
        argv:        %w(jump_over_sub_sub_command arg1 arg2),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1", "arg2"],
      },
      {
        argv:        %w(jump_over_sub_sub_command arg1 arg2 arg3),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1", "arg2", "arg3"],
      },
      {
        argv:              %w(jump_over_sub_sub_command --help -ignore-option),
        exception_message: "Undefined option. \"-ignore-option\"",
      },
      {
        argv:              %w(jump_over_sub_sub_command -ignore-option --help),
        exception_message: "Undefined option. \"-ignore-option\"",
      },
      {
        argv:              %w(jump_over_sub_sub_command -m),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv:              %w(jump_over_sub_sub_command --missing-option),
        exception_message: "Undefined option. \"--missing-option\"",
      },
      {
        argv:              %w(jump_over_sub_sub_command -m arg1),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv:              %w(jump_over_sub_sub_command arg1 -m),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv:              %w(jump_over_sub_sub_command -m -d),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv: %w(jump_over_sub_sub_command --help),
      },
      {
        argv: %w(jump_over_sub_sub_command --help ignore-arg),
      },
      {
        argv: %w(jump_over_sub_sub_command ignore-arg --help),
      },
    ],
    sub_sub_command_case: [
      {
        argv:        %w(sub_command sub_sub_command),
        expect_opts: ReturnOptsType.new,
        expect_args: [] of String,
      },
      {
        argv:        %w(sub_command sub_sub_command arg1),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1"],
      },
      {
        argv:        %w(sub_command sub_sub_command arg1 arg2),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1", "arg2"],
      },
      {
        argv:        %w(sub_command sub_sub_command arg1 arg2 arg3),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1", "arg2", "arg3"],
      },
      {
        argv:              %w(sub_command sub_sub_command --help -ignore-option),
        exception_message: "Undefined option. \"-ignore-option\"",
      },
      {
        argv:              %w(sub_command sub_sub_command -ignore-option --help),
        exception_message: "Undefined option. \"-ignore-option\"",
      },
      {
        argv:              %w(sub_command sub_sub_command -m),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv:              %w(sub_command sub_sub_command --missing-option),
        exception_message: "Undefined option. \"--missing-option\"",
      },
      {
        argv:              %w(sub_command sub_sub_command -m arg1),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv:              %w(sub_command sub_sub_command arg1 -m),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv:              %w(sub_command sub_sub_command -m -d),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv: %w(sub_command sub_sub_command --help),
      },
      {
        argv: %w(sub_command sub_sub_command --help ignore-arg),
      },
      {
        argv: %w(sub_command sub_sub_command ignore-arg --help),
      },
    ],
  }
)

macro spec_for_alias_name(spec_class_name, main_help_message, sub_1_help_message, sub_2_help_message, spec_cases_hash)
  {% for key, spec_case_hash in spec_cases_hash %}
    {% for spec_case, index in spec_case_hash %}
      {% class_name = (spec_class_name.stringify + key.stringify.camelcase + index.stringify).id %}
      # define dsl
      class {{class_name}} < Clim
        main_command
        run do |opts, args|
          check_opts_and_args({{main_help_message}}, {{spec_case}})
        end

        sub do
          command "sub_command_1"
          alias_name "alias_sub_command_1"
          run do |opts, args|
            check_opts_and_args({{sub_1_help_message}}, {{spec_case}})
          end

          sub do
            command "sub_sub_command_1"
            run do |opts, args|
            end
          end

          command "sub_command_2"
          alias_name "alias_sub_command_2", "alias_sub_command_2_second"
          run do |opts, args|
            check_opts_and_args({{sub_2_help_message}}, {{spec_case}})
          end

        end
      end

      # spec
      describe "alias name case," do
        describe "if argv is " + {{spec_case["argv"].stringify}} + "," do
          {% if spec_case.keys.includes?("expect_opts".id) %}
            it "opts and args are given as arguments of run block." do
              {{class_name}}.start_main({{spec_case["argv"]}})
            end
          {% elsif spec_case.keys.includes?("exception_message".id) %}
            it "raises an Exception." do
              expect_raises(Exception, {{spec_case["exception_message"]}}) do
                {{class_name}}.start_main({{spec_case["argv"]}})
              end
            end
          {% else %}
            it "display help." do
              io = IO::Memory.new
              {{class_name}}.start_main({{spec_case["argv"]}}, io)
              {% if key == "main_command_case" %}
                io.to_s.should eq {{main_help_message}}
              {% elsif key == "sub_1_command_case" %}
                io.to_s.should eq {{sub_1_help_message}}
              {% elsif key == "sub_2_command_case" %}
                io.to_s.should eq {{sub_2_help_message}}
              {% end %}
            end
          {% end %}
        end
      end
    {% end %}
  {% end %}
end

spec_for_alias_name(
  spec_class_name: SubCommandWithAliasName,
  main_help_message: <<-HELP_MESSAGE

                       Command Line Interface Tool.

                       Usage:

                         main_command [options] [arguments]

                       Options:

                         --help                           Show this help.

                       Sub Commands:

                         sub_command_1, alias_sub_command_1                               Command Line Interface Tool.
                         sub_command_2, alias_sub_command_2, alias_sub_command_2_second   Command Line Interface Tool.


                     HELP_MESSAGE,
  sub_1_help_message: <<-HELP_MESSAGE

                        Command Line Interface Tool.

                        Usage:

                          sub_command_1 [options] [arguments]

                        Options:

                          --help                           Show this help.

                        Sub Commands:

                          sub_sub_command_1   Command Line Interface Tool.


                      HELP_MESSAGE,
  sub_2_help_message: <<-HELP_MESSAGE

                        Command Line Interface Tool.

                        Usage:

                          sub_command_2 [options] [arguments]

                        Options:

                          --help                           Show this help.


                      HELP_MESSAGE,
  spec_cases_hash: {
    main_command_case: [
      {
        argv:        %w(),
        expect_opts: ReturnOptsType.new,
        expect_args: [] of String,
      },
      {
        argv:        %w(arg1),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1"],
      },
      {
        argv:        %w(arg1 arg2),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1", "arg2"],
      },
      {
        argv:        %w(arg1 arg2 arg3),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1", "arg2", "arg3"],
      },
      {
        argv:              %w(-h),
        exception_message: "Undefined option. \"-h\"",
      },
      {
        argv:              %w(--help -ignore-option),
        exception_message: "Undefined option. \"-ignore-option\"",
      },
      {
        argv:              %w(-ignore-option --help),
        exception_message: "Undefined option. \"-ignore-option\"",
      },
      {
        argv: %w(--help),
      },
      {
        argv: %w(--help ignore-arg),
      },
      {
        argv: %w(ignore-arg --help),
      },
    ],
    sub_1_command_case: [
      {
        argv:        %w(sub_command_1),
        expect_opts: ReturnOptsType.new,
        expect_args: [] of String,
      },
      {
        argv:        %w(alias_sub_command_1),
        expect_opts: ReturnOptsType.new,
        expect_args: [] of String,
      },
      {
        argv:        %w(sub_command_1 arg1),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1"],
      },
      {
        argv:        %w(alias_sub_command_1 arg1),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1"],
      },
      {
        argv:        %w(sub_command_1 arg1 arg2),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1", "arg2"],
      },
      {
        argv:        %w(alias_sub_command_1 arg1 arg2),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1", "arg2"],
      },
      {
        argv:        %w(sub_command_1 arg1 arg2 arg3),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1", "arg2", "arg3"],
      },
      {
        argv:        %w(alias_sub_command_1 arg1 arg2 arg3),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1", "arg2", "arg3"],
      },
      {
        argv:              %w(sub_command_1 --help -ignore-option),
        exception_message: "Undefined option. \"-ignore-option\"",
      },
      {
        argv:              %w(alias_sub_command_1 --help -ignore-option),
        exception_message: "Undefined option. \"-ignore-option\"",
      },
      {
        argv:              %w(sub_command_1 -ignore-option --help),
        exception_message: "Undefined option. \"-ignore-option\"",
      },
      {
        argv:              %w(alias_sub_command_1 -ignore-option --help),
        exception_message: "Undefined option. \"-ignore-option\"",
      },
      {
        argv:              %w(sub_command_1 -m),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv:              %w(alias_sub_command_1 -m),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv:              %w(sub_command_1 --missing-option),
        exception_message: "Undefined option. \"--missing-option\"",
      },
      {
        argv:              %w(alias_sub_command_1 --missing-option),
        exception_message: "Undefined option. \"--missing-option\"",
      },
      {
        argv:              %w(sub_command_1 -m arg1),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv:              %w(alias_sub_command_1 -m arg1),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv:              %w(sub_command_1 arg1 -m),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv:              %w(alias_sub_command_1 arg1 -m),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv:              %w(sub_command_1 -m -d),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv:              %w(alias_sub_command_1 -m -d),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv: %w(sub_command_1 --help),
      },
      {
        argv: %w(alias_sub_command_1 --help),
      },
      {
        argv: %w(sub_command_1 --help ignore-arg),
      },
      {
        argv: %w(alias_sub_command_1 --help ignore-arg),
      },
      {
        argv: %w(sub_command_1 ignore-arg --help),
      },
      {
        argv: %w(alias_sub_command_1 ignore-arg --help),
      },
    ],
    sub_2_command_case: [
      {
        argv:        %w(sub_command_2),
        expect_opts: ReturnOptsType.new,
        expect_args: [] of String,
      },
      {
        argv:        %w(alias_sub_command_2),
        expect_opts: ReturnOptsType.new,
        expect_args: [] of String,
      },
      {
        argv:        %w(alias_sub_command_2_second),
        expect_opts: ReturnOptsType.new,
        expect_args: [] of String,
      },
      {
        argv:        %w(sub_command_2 arg1),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1"],
      },
      {
        argv:        %w(alias_sub_command_2 arg1),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1"],
      },
      {
        argv:        %w(alias_sub_command_2_second arg1),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1"],
      },
      {
        argv:        %w(sub_command_2 arg1 arg2),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1", "arg2"],
      },
      {
        argv:        %w(alias_sub_command_2 arg1 arg2),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1", "arg2"],
      },
      {
        argv:        %w(alias_sub_command_2_second arg1 arg2),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1", "arg2"],
      },
      {
        argv:        %w(sub_command_2 arg1 arg2 arg3),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1", "arg2", "arg3"],
      },
      {
        argv:        %w(alias_sub_command_2 arg1 arg2 arg3),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1", "arg2", "arg3"],
      },
      {
        argv:        %w(alias_sub_command_2_second arg1 arg2 arg3),
        expect_opts: ReturnOptsType.new,
        expect_args: ["arg1", "arg2", "arg3"],
      },
      {
        argv:              %w(sub_command_2 --help -ignore-option),
        exception_message: "Undefined option. \"-ignore-option\"",
      },
      {
        argv:              %w(alias_sub_command_2 --help -ignore-option),
        exception_message: "Undefined option. \"-ignore-option\"",
      },
      {
        argv:              %w(alias_sub_command_2_second --help -ignore-option),
        exception_message: "Undefined option. \"-ignore-option\"",
      },
      {
        argv:              %w(sub_command_2 -ignore-option --help),
        exception_message: "Undefined option. \"-ignore-option\"",
      },
      {
        argv:              %w(alias_sub_command_2 -ignore-option --help),
        exception_message: "Undefined option. \"-ignore-option\"",
      },
      {
        argv:              %w(alias_sub_command_2_second -ignore-option --help),
        exception_message: "Undefined option. \"-ignore-option\"",
      },
      {
        argv:              %w(sub_command_2 -m),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv:              %w(alias_sub_command_2 -m),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv:              %w(alias_sub_command_2_second -m),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv:              %w(sub_command_2 --missing-option),
        exception_message: "Undefined option. \"--missing-option\"",
      },
      {
        argv:              %w(alias_sub_command_2 --missing-option),
        exception_message: "Undefined option. \"--missing-option\"",
      },
      {
        argv:              %w(alias_sub_command_2_second --missing-option),
        exception_message: "Undefined option. \"--missing-option\"",
      },
      {
        argv:              %w(sub_command_2 -m arg1),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv:              %w(alias_sub_command_2 -m arg1),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv:              %w(alias_sub_command_2_second -m arg1),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv:              %w(sub_command_2 arg1 -m),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv:              %w(alias_sub_command_2 arg1 -m),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv:              %w(alias_sub_command_2_second arg1 -m),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv:              %w(sub_command_2 -m -d),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv:              %w(alias_sub_command_2 -m -d),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv:              %w(alias_sub_command_2_second -m -d),
        exception_message: "Undefined option. \"-m\"",
      },
      {
        argv: %w(sub_command_2 --help),
      },
      {
        argv: %w(alias_sub_command_2 --help),
      },
      {
        argv: %w(alias_sub_command_2_second --help),
      },
      {
        argv: %w(sub_command_2 --help ignore-arg),
      },
      {
        argv: %w(alias_sub_command_2 --help ignore-arg),
      },
      {
        argv: %w(alias_sub_command_2_second --help ignore-arg),
      },
      {
        argv: %w(sub_command_2 ignore-arg --help),
      },
      {
        argv: %w(alias_sub_command_2 ignore-arg --help),
      },
      {
        argv: %w(alias_sub_command_2_second ignore-arg --help),
      },
    ],
  }
)

class SubCommandWhenDuplicateCommandName < Clim
  main_command
  run do |opts, args|
  end

  sub do
    command "sub_command"
    run do |opts, args|
    end

    command "sub_command" # Duplicate name.
    run do |opts, args|
    end
  end
end

describe "Call the command." do
  it "raises an Exception when duplicate command name." do
    expect_raises(Exception, "There are duplicate registered commands. [sub_command]") do
      SubCommandWhenDuplicateCommandName.start_main([] of String)
    end
  end
end

class SubCommandWhenDuplicateAliasNameCase1 < Clim
  main_command
  run do |opts, args|
  end

  sub do
    command "sub_command"
    alias_name "sub_command" # duplicate
    run do |opts, args|
    end
  end
end

describe "Call the command." do
  it "raises an Exception when duplicate command name (case1)." do
    expect_raises(Exception, "There are duplicate registered commands. [sub_command]") do
      SubCommandWhenDuplicateAliasNameCase1.start_main([] of String)
    end
  end
end

class SubCommandWhenDuplicateAliasNameCase2 < Clim
  main_command
  run do |opts, args|
  end

  sub do
    command "sub_command1"
    alias_name "sub_command1", "sub_command2", "sub_command2" # duplicate "sub_command1" and "sub_command2"
    run do |opts, args|
    end
  end
end

describe "Call the command." do
  it "raises an Exception when duplicate command name (case2)." do
    expect_raises(Exception, "There are duplicate registered commands. [sub_command1,sub_command2]") do
      SubCommandWhenDuplicateAliasNameCase2.start_main([] of String)
    end
  end
end

class SubCommandWhenDuplicateAliasNameCase3 < Clim
  main_command
  run do |opts, args|
  end

  sub do
    command "sub_command1"
    alias_name "alias_name1"
    run do |opts, args|
    end

    command "sub_command2"
    alias_name "alias_name2"
    run do |opts, args|
    end

    command "sub_command3"
    alias_name "sub_command1", "sub_command2", "alias_name1", "alias_name2"
    run do |opts, args|
    end
  end
end

describe "Call the command." do
  it "raises an Exception when duplicate command name (case3)." do
    expect_raises(Exception, "There are duplicate registered commands. [sub_command1,sub_command2,alias_name1,alias_name2]") do
      SubCommandWhenDuplicateAliasNameCase3.start_main([] of String)
    end
  end
end
