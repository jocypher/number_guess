#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Generate random secret number between 1 and 1000
G_NUMBER=$(($RANDOM % 1000 + 1))
echo $G_NUMBER

# Ask for username
echo "Enter your username:"
read USERNAME

# Check if the user exists in the database
USER_CHECK=$($PSQL "SELECT name FROM number_guess WHERE name='$USERNAME'")

if [[ -z $USER_CHECK ]]
then
  # If it's a new user
  echo -e "Welcome, $USERNAME! It looks like this is your first time here."
  ADD_USER=$($PSQL "INSERT INTO number_guess(name, games_played, best_game) VALUES('$USERNAME', 0, NULL);")
else
  # If it's a returning user
  USERNAME_FROM_DB=$($PSQL "SELECT name FROM number_guess WHERE name='$USERNAME'")
  GAMES_PLAYED=$($PSQL "SELECT games_played FROM number_guess WHERE name='$USERNAME'")
  BEST_GAME=$($PSQL "SELECT best_game FROM number_guess WHERE name='$USERNAME'")

  # Output returning user information (without singular/plural logic)
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took ${BEST_GAME:-no} guesses."
fi

# Start guessing the secret number
COUNT=0
echo -e "Guess the secret number between 1 and 1000:"

# Game loop
while true; do
  read USER_INPUT

  # Check if input is a valid integer
  if ! [[ $USER_INPUT =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  # Increment guess count
  ((COUNT++))

  if [[ $USER_INPUT -lt $G_NUMBER ]]; then
    echo "It's higher than that, guess again:"
  elif [[ $USER_INPUT -gt $G_NUMBER ]]; then
    echo "It's lower than that, guess again:"
  else
    echo "You guessed it in $COUNT tries. The secret number was $G_NUMBER. Nice job!"
    
    # Update user statistics in the database
    GAMES_PLAYED=$((GAMES_PLAYED + 1))
    UPDATE_GAMES_PLAYED=$($PSQL "UPDATE number_guess SET games_played=$GAMES_PLAYED WHERE name='$USERNAME'")

    # Update best game if necessary
    if [[ -z $BEST_GAME || $COUNT -lt $BEST_GAME ]]; then
      UPDATE_BEST_GAME=$($PSQL "UPDATE number_guess SET best_game=$COUNT WHERE name='$USERNAME'")
    fi
    break
  fi
done
