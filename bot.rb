#!/usr/bin/env ruby

# This program requires the xmpp4r gem. Install with: gem install xmpp4r

require 'xmpp4r'
require 'xmpp4r/muc/helper/simplemucclient'
require 'yaml'

# enable this to see where your code blows up
Jabber::debug = true

class Bot
    def initialize(config)
        @config = config
        @client = Jabber::Client.new(Jabber::JID.new(config[:bot_jid]))
        @client.connect
        @client.auth(config[:bot_password])
        @client.send(Jabber::Presence.new(:chat, @config[:bot_status]))
        @start_time = Time.now.to_i
    end

    def install_bot(type, client)
        client.add_message_callback do |message|
            # if the message has a body, continue (might be a status message otherwise)
            if message.body
                # only react if it's a :chat or :groupchat message, depending on what has been passed in type
                if message.type == type
                    # don't react to history messages (just wait for 3 seconds) and don't react to our own messages
                    if (Time.now.to_i - @start_time > 3) && (message.from != "#{@config[:chat_jid]}/#{@config[:bot_alias]}")
                        if rand() < 0.3
                            sentences = message.body.split(/[\.\?!]/).map { |x| x.strip }.reject { |x| x.empty? }
                            STDERR.puts "I found the following sentences:"
                            STDERR.puts sentences.to_yaml
                            sentences.each do |sentence|
                                next if sentence.include?('?')
                                found_index = nil
                                found_term = nil
                                ['hat', 'hatte', 'kann', 'konnte', 'ist', 'wird', 'war', 'weiß', 'wusste'].each do |term|
                                    index = sentence.downcase.index(Regexp.new("\s#{term}\s"))
                                    if index != nil
                                        found_index = index
                                        found_term = term
                                    end
                                end
                                if found_index != nil
                                    sleep 2.0
                                    answer = Jabber::Message.new(message.from)
                                    answer.type = type
                                    rest = sentence[found_index, sentence.size].strip
                                    rest = rest[found_term.size, rest.size].strip
                                    ['ich', 'er', 'sie', 'es', 'man'].each do |term|
                                        if rest.downcase =~ Regexp.new("^#{term}\s")
                                            rest = rest[term.size, rest.size].strip
                                        end
                                    end
                                    unless rest.strip.empty?
                                        rest += '!'
                                        answer.body = "Deine Mutter #{found_term} #{rest}"
                                        client.send(answer)
                                        if rand() < 0.3
                                            sleep 3.0
                                            answer = Jabber::Message.new(message.from)
                                            answer.type = type
                                            answer.body = ["Pass auf was du sagst!", "Du Opfer.", "Du Penner."].sample
                                            client.send(answer)
                                        end
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    def run_single
        install_bot(:chat, @client)
        Thread.stop
        @client.close
    end

    def run_chat
        @muc = Jabber::MUC::MUCClient.new(@client)
        @muc.join(Jabber::JID.new("#{@config[:chat_jid]}/#{@config[:bot_alias]}"))
        install_bot(:groupchat, @muc)
        Thread.stop
        @client.close
    end
end

config = YAML::load(File::read('config.yaml'))
puts config.to_yaml
bot = Bot.new(config)

# Run the bot as a normal user you may chat with for testing purposes
bot.run_single

# Let the bot join a chat room when it's working!
# bot.run_chat
