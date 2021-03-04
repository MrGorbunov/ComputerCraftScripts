-- Random Number Guessing Game
-- 
-- Based on the wiki tutorials
-- http://computercraft.info/wiki/Guess_The_Number_(tutorial)
--
-- Meant to run on a computer but a turtle works too ig


-- Setup
do
  numb = math.random(1, 100)
  attempt = 0
  maxAttempts = 6
  local guess = -1

  term.clear()
  textutils.slowPrint("You have " .. maxAttempts .. " guesses...")
  textutils.slowPrint("Guess away!")
end


-- Game Loop
do
  while (attempt <= maxAttempts) and (guess ~= numb) do
    write("Guess a number from 1 to 100: ")
    attempt = attempt + 1
    guess = io.read()
    guess = tonumber(guess)

    if guess < numb then
      print("> too low")
    elseif guess > numb then
      print("> too high")
    end
  end
end


-- Closing Loop
do
  term.clear()

  if attempt > maxAttempts then
    textutils.slowPrint("Good try, but better luck next time")
  else
    textutils.slowPrint("Congrats! It only took you " .. attempt .. " guesses.")
  end
end
