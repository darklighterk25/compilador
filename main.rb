require 'fox16'
include Fox
app = FXApp.new

require_relative './ide/ide'
IDE.new(app)

app.create
app.run