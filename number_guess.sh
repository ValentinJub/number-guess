#! /bin/bash

RANDOM_NUM=$(( 1 + $RANDOM % 1000))
PSQL="psql -U freecodecamp number_guess -t --no-align -c"

USER_MENU() {
#ask for name
echo -e "\nEnter your username:\n"
read USERNAME

#check if name matches a user_id
USER_ID=$($PSQL "SELECT user_id FROM users WHERE name = '$USERNAME';")

#if user_id does not exist
if [[ -z $USER_ID ]] 
then
  #add new user to the database
	INSERT_NEW_USER=$($PSQL "INSERT INTO users(name) VALUES('$USERNAME')")
	#check successful insert
	if [[ $INSERT_NEW_USER == "INSERT 0 1" ]]
	then
	  #fetch user_id
		USER_ID=$($PSQL "SELECT user_id FROM users WHERE name = '$USERNAME';")
		#print first welcome message 
		echo "Welcome, $USERNAME! It looks like this is your first time here."
	#insert unsuccessful
	else
		echo -e "\nError inserting new user in database, details are: $INSERT_NEW_USER"
		exit 1
	fi
#if known
else
	#fetch games played and best score
	GAMES_AND_SCORE=$($PSQL "SELECT games_played, best_game FROM users WHERE user_id=$USER_ID")
	IFS='|' read GAMES_PLAYED BEST_SCORE < <(echo $GAMES_AND_SCORE)
	#print repeat welcome message
	echo $(echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_SCORE guesses." | sed -E 's/^ +| +$//g')
fi
}

#Variable used in USER_MENU are available
#to use in the GAME function, look into scope
#variable in Bash for more context

GAME() {
FOUND=false
NUMBER_OF_GUESS=1
#ask to guess the secret number
echo -e "\nGuess the secret number between 1 and 1000:"

while [[ $FOUND==false ]] 
    do
    #read GUESS
    read GUESS
    #Is it a number?
    if [[ $GUESS =~ ^[0-9]+$ ]] 
    then
        #If yes, evaluate it
        if [[ $GUESS > $RANDOM_NUM ]] 
        then
            echo "It's lower than that, guess again:"
            ((NUMBER_OF_GUESS++))
        elif [[ $GUESS < $RANDOM_NUM ]]
        then
            echo "It's higher than that, guess again:"
            ((NUMBER_OF_GUESS++))
        elif [[ $GUESS == $RANDOM_NUM ]]
        then
            SCORE_SCREEN
        fi
    else
        #If no, ask for int and repeat
        echo "That is not an integer, guess again:"
    fi
done
}

SCORE_SCREEN() {
    #if recuring user, we have their best score
    if ! [[ -z $BEST_SCORE ]]
    then
        #compare it with number of guess
        #if new best score
        if [[ $NUMBER_OF_GUESS < $BEST_SCORE ]]
        then
            INSERT_NEW_BEST=$($PSQL "UPDATE users SET best_game=$NUMBER_OF_GUESS WHERE user_id=$USER_ID;")
        fi
    #if first best score insert it
    else
            INSERT_NEW_BEST=$($PSQL "UPDATE users SET best_game=$NUMBER_OF_GUESS WHERE user_id=$USER_ID;")
    fi 
    #increment number of games played
    INCREMENT_GAMES_PLAYED=$($PSQL "UPDATE users SET games_played=games_played + 1 WHERE user_id=$USER_ID;")
    #display score message
    echo $(echo "You guessed it in $NUMBER_OF_GUESS tries. The secret number was $RANDOM_NUM. Nice job!" | sed -E 's/^ +| +$//g')
    exit 0
}

# ~~~~~~ Launch the script here ~~~~~~~~
USER_MENU
GAME
