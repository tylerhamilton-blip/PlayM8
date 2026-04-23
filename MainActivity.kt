package com.example.playm8_questionnaire

//Imports
import android.annotation.SuppressLint
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import com.example.playm8_questionnaire.ui.theme.PlayM8_QuestionnaireTheme

//Additional Imports
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.ExperimentalLayoutApi

import androidx.compose.foundation.clickable
import androidx.compose.ui.Alignment
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.draw.clip

class MainActivity : ComponentActivity() {
    @SuppressLint("UnusedMaterial3ScaffoldPaddingParameter")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            PlayM8_QuestionnaireTheme {
                Scaffold(modifier = Modifier.fillMaxSize()) {
                    QuestionnaireScreen()
                }
            }
        }
    }
}

//Main UI
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun QuestionnaireScreen() {

    //Variables
    var page by remember { mutableStateOf(0) }
    var birthday by remember { mutableStateOf("") } //Question 1
    var username by remember { mutableStateOf("") } //Question 2
    var accountType by remember { mutableStateOf("") } //Question 3
    var otherPlatformText by remember { mutableStateOf("") } //Question 4
    var playMode by remember { mutableStateOf("") } //Question 5

    val platforms = listOf(
        "PC","Playstation","Xbox","Nintendo Switch","Mobile","Other"
    )

    val genres = listOf(
        "Action","Adventure","RPG","Strategy","Simulation",
        "Shooter","Platformer","Puzzle","Horror","Survival",
        "Roguelike","Indie","Fighting","Sports","Racing",
        "Sandbox","MMO","Visual Novel","Card","Party"
    )

    //Question Variables
    var selectedPlatforms by remember { mutableStateOf(setOf<String>()) }
    var selectedGenres by remember { mutableStateOf(setOf<String>()) }
    var storyImportance by remember { mutableStateOf(3f) }
    var worldType by remember { mutableStateOf("") }
    var difficulty by remember { mutableStateOf("") }
    var sessionLength by remember { mutableStateOf("") }
    var competitive by remember { mutableStateOf("") }
    var grinding by remember { mutableStateOf("") }
    var selectedArtStyles by remember { mutableStateOf(setOf<String>()) }
    var selectedTones by remember { mutableStateOf(setOf<String>()) } //selected = checkbox question btw
    var releasePreference by remember { mutableStateOf("") }
    var replayability by remember { mutableStateOf(3f) }
    var budget by remember { mutableStateOf("") }
    var hasSteam by remember { mutableStateOf("") }
    var gameplayElements by remember { mutableStateOf(setOf<String>()) }


    val scroll = rememberScrollState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(top = 80.dp, start = 20.dp, end = 20.dp, bottom = 20.dp)
            .verticalScroll(scroll)
    ) {

        //Progress Bar
        LinearProgressIndicator(
            progress = (page + 1) / 18f,
            modifier = Modifier
                .fillMaxWidth()
                .height(8.dp)
                .clip(RoundedCornerShape(50)),
            color = MaterialTheme.colorScheme.primary,
            trackColor = Color(0xFFE0E0E0)
        )

        //Text for progress bar
        Spacer(Modifier.height(12.dp))

        Text(
            text = "Question ${page + 1} of 18",
            style = MaterialTheme.typography.labelMedium,
            color = Color.Gray
        )

        Spacer(Modifier.height(16.dp))

        //Questions
        when (page) {

            //Make questions required, edit next button later
            // Birthday
            //4-7 --> make it impossible to enter down to expand the textbox
            // 4-22 --> fix / issue
            0 -> {
                Text("When's your birthday?", style = MaterialTheme.typography.headlineSmall)

                Spacer(Modifier.height(16.dp))

                TextField(
                    value = birthday,
                    onValueChange = { input ->

                        // Keep only digits
                        val digits = input.filter { it.isDigit() }.take(8)

                        // Format as MM/DD/YYYY
                        val formatted = buildString {
                            for (i in digits.indices) {
                                append(digits[i])
                                if (i == 1 || i == 3) append("/") // auto add /
                            }
                        }

                        birthday = formatted
                    },
                    label = { Text("MM/DD/YYYY") },
                    singleLine = true
                )
            }

            // Account Type
            /*
            1 -> {

                Text("Is this account for you or for a child?", style = MaterialTheme.typography.headlineSmall)

                Spacer(Modifier.height(16.dp))

                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.padding(vertical = 8.dp)
                ) {
                    RadioButton(
                        selected = accountType == "Me",
                        onClick = { accountType = "Me" }
                    )
                    Text("For me")
                }

                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.padding(vertical = 8.dp)
                ) {
                    RadioButton(
                        selected = accountType == "Child",
                        onClick = { accountType = "Child" }
                    )
                    Text("For a child")
                }
            }
             */

            // Username
            //4-7 --> make it impossible to enter down to expand the textboxpow
            1 -> {

                Text("Account Name (pick a username)", style = MaterialTheme.typography.headlineSmall)

                Spacer(Modifier.height(16.dp))

                TextField(
                    value = username,
                    onValueChange = { username = it },
                    label = { Text("Username") }
                )
            }

            // Platforms
            2 -> {

                Text("Which platforms do you currently play games on/have access to?",
                    style = MaterialTheme.typography.headlineSmall)

                Spacer(Modifier.height(16.dp))

                platforms.forEach { platform ->

                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.padding(vertical = 8.dp)
                    ) {

                        Checkbox(
                            checked = selectedPlatforms.contains(platform),
                            onCheckedChange = {

                                selectedPlatforms =
                                    if (selectedPlatforms.contains(platform))
                                        selectedPlatforms - platform
                                    else
                                        selectedPlatforms + platform
                            }
                        )

                        Text(platform)

                    }

                    if (platform == "Other" && selectedPlatforms.contains("Other")) {

                        Spacer(Modifier.height(16.dp))

                        TextField(
                            value = otherPlatformText,
                            onValueChange = { otherPlatformText = it },
                            label = { Text("Enter platform") }
                        )

                    }

                }

            }

            // Genre Bubbles
            3 -> {

                Text("What genres do you most enjoy?",
                    style = MaterialTheme.typography.headlineSmall)

                Spacer(Modifier.height(16.dp))

                Text("Tap bubbles to select genres:")

                Spacer(Modifier.height(16.dp))

                FlowRow(
                    horizontalArrangement = Arrangement.spacedBy(10.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {

                    genres.forEach { genre ->

                        FilterChip(
                            selected = selectedGenres.contains(genre),
                            onClick = {
                                selectedGenres =
                                    if (selectedGenres.contains(genre))
                                        selectedGenres - genre
                                    else
                                        selectedGenres + genre
                            },
                            label = { Text(genre) },
                            shape = RoundedCornerShape(50),
                            colors = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = MaterialTheme.colorScheme.primary,
                                selectedLabelColor = Color.White,
                                containerColor = Color(0xFFF0F0F0),
                                labelColor = Color.Black
                            )
                        )

                    }

                }

            }

            // Single-player / Multiplayer Preference
            4 -> {
                Text("Do you prefer single-player or multiplayer games?",
                    style = MaterialTheme.typography.headlineSmall)

                Spacer(Modifier.height(16.dp))

                val options = listOf("Single-player", "Multiplayer", "Co-op", "No preference")

                options.forEach { option ->
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.padding(vertical = 8.dp)
                    ) {
                        RadioButton(
                            selected = playMode == option,
                            onClick = { playMode = option }
                        )
                        Text(option)
                    }
                }
            }

            // Story Importance
            5 -> {

                Text("How important is story in a game to you?",
                    style = MaterialTheme.typography.headlineSmall)

                Spacer(Modifier.height(16.dp))

                Slider(
                    value = storyImportance,
                    onValueChange = { storyImportance = it },
                    valueRange = 1f..5f,
                    steps = 3
                )

                Text("Value: ${storyImportance.toInt()}")
            }

            //Open World vs Linear
            6 -> {
                Text("Do you prefer open-world exploration or structured/linear gameplay?",
                    style = MaterialTheme.typography.headlineSmall)

                Spacer(Modifier.height(16.dp))

                val options = listOf("Open-world", "Linear", "Hybrid", "No Preference")

                options.forEach { option ->
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.padding(vertical = 8.dp)
                    ) {
                        RadioButton(
                            selected = worldType == option,
                            onClick = { worldType = option }
                        )
                        Text(option)
                    }
                }
            }

            //Difficulty
            7 -> {
                Text("How challenging do you like your games to be?",
                    style = MaterialTheme.typography.headlineSmall)

                Spacer(Modifier.height(16.dp))

                val options = listOf("Casual/Relaxed", "Moderate", "Challenging", "Extremely Difficult")

                options.forEach { option ->
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.padding(vertical = 8.dp)
                    ){
                        RadioButton(
                            selected = difficulty == option,
                            onClick = { difficulty = option }
                        )
                        Text(option)
                    }
                }
            }

            //Session Length
            8 -> {
                Text("How much time do you usually have per gaming session?",
                    style = MaterialTheme.typography.headlineSmall)

                Spacer(Modifier.height(16.dp))

                val options = listOf("< 30 minutes", "30 - 60 minutes", "1 - 2 hours", "2+ hours")

                options.forEach { option ->
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.padding(vertical = 8.dp)
                    ) {
                        RadioButton(
                            selected = sessionLength == option,
                            onClick = { sessionLength = option }
                        )
                        Text(option)
                    }
                }
            }


            //Competitive
            9 -> {
                Text("Do you enjoy competitive gameplay?",
                    style = MaterialTheme.typography.headlineSmall)

                Spacer(Modifier.height(16.dp))

                val options = listOf("Yes", "Sometimes", "No")

                options.forEach { option ->
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.padding(vertical = 8.dp)
                    ){
                        RadioButton(
                            selected = competitive == option,
                            onClick = { competitive = option }
                        )
                        Text(option)
                    }
                }
            }

            //Grinding System
            10 -> {
                Text("Do you enjoy grinding/leveling systems?",
                    style = MaterialTheme.typography.headlineSmall)

                Spacer(Modifier.height(16.dp))

                val options = listOf("Yes", "Neutral", "No")

                options.forEach { option ->
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.padding(vertical = 8.dp)
                    ){
                        RadioButton(
                            selected = grinding == option,
                            onClick = { grinding = option }
                        )
                        Text(option)
                    }
                }
            }

            //Art Style
            11 -> {
                Text("What art styles do you prefer?",
                    style = MaterialTheme.typography.headlineSmall)

                Spacer(Modifier.height(16.dp))

                val options = listOf(
                    "Realistic","Stylized","Pixel Art","Anime",
                    "Cartoon","Retro","Indie/Minimalist","No Preference"
                )

                options.forEach { option ->
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.padding(vertical = 8.dp)
                    ){
                        Checkbox(
                            checked = selectedArtStyles.contains(option),
                            onCheckedChange = {
                                selectedArtStyles =
                                    if (option == "No Preference") {
                                        setOf("No Preference")
                                    } else {
                                        (selectedArtStyles - "No Preference").let {
                                            if (it.contains(option)) it - option else it + option
                                        }
                                    }
                            }
                        )
                        Text(option)
                    }
                }
            }

            //Tone
            12 -> {
                Text("What tone do you prefer in games?",
                    style = MaterialTheme.typography.headlineSmall)

                Spacer(Modifier.height(16.dp))

                val options = listOf(
                    "Dark/Serious","Light Hearted","Funny/Satirical",
                    "Emotional/Story Driven","Horror/Tense",
                    "Epic/Cinematic","No Preference"
                )

                options.forEach { option ->
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.padding(vertical = 8.dp)
                    ) {
                        Checkbox(
                            checked = selectedTones.contains(option),
                            onCheckedChange = {
                                selectedTones =
                                    if (option == "No Preference") {
                                        setOf("No Preference")
                                    } else {
                                        (selectedTones - "No Preference").let {
                                            if (it.contains(option)) it - option else it + option
                                        }
                                    }
                            }
                        )
                        Text(option)
                    }
                }
            }

            //Gameplay Elements
            13 -> {
                Text("What gameplay elements do you enjoy the most?",
                    style = MaterialTheme.typography.headlineSmall)

                Spacer(Modifier.height(16.dp))

                val options = listOf(
                    "Character customization","Skill trees","Loot systems","Crafting",
                    "Exploration","Puzzles","Base building","Dialogue choices",
                    "Romance options","Roguelike mechanics","Strategy / Planning","Fast reflex combat"
                )

                options.forEach { element ->
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.padding(vertical = 8.dp)
                    ){
                        Checkbox(
                            checked = gameplayElements.contains(element),
                            onCheckedChange = {
                                gameplayElements =
                                    if (gameplayElements.contains(element))
                                        gameplayElements - element
                                    else
                                        gameplayElements + element
                            }
                        )
                        Text(element)
                    }
                }
            }

            //Release date
            14 -> {
                Text("Do you prefer newer releases or older classics?",
                    style = MaterialTheme.typography.headlineSmall)

                Spacer(Modifier.height(16.dp))

                val options = listOf(
                    "New (last 2–3 years)",
                    "Mix of both",
                    "Older/retro games",
                    "No Preference"
                )

                options.forEach { option ->
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.padding(vertical = 8.dp)
                    ){
                        RadioButton(
                            selected = releasePreference == option,
                            onClick = { releasePreference = option }
                        )
                        Text(option)
                    }
                }
            }

            //Replayability
            15 -> {
                Text("How important is replayability to you?",
                    style = MaterialTheme.typography.headlineSmall)

                Spacer(Modifier.height(16.dp))

                Slider(
                    value = replayability,
                    onValueChange = { replayability = it },
                    valueRange = 1f..5f,
                    steps = 3
                )

                Text("Value: ${replayability.toInt()}")
            }

            //BUDGET!!!!
            16 -> {
                Text("What is your budget range?",
                    style = MaterialTheme.typography.headlineSmall)

                Spacer(Modifier.height(16.dp))

                val options = listOf(
                    "Free only","Under $5","Under $10","Under $20",
                    "Under $30","$30–60","No budget limit"
                )

                options.forEach { option ->
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.padding(vertical = 8.dp)
                    ){
                        RadioButton(
                            selected = budget == option,
                            onClick = { budget = option }
                        )
                        Text(option)
                    }
                }
            }

            //Steam?
            //**Find a way to direct this to signing in on steam
            17 -> {
                Text("Do you have a Steam account?",
                    style = MaterialTheme.typography.headlineSmall)

                Spacer(Modifier.height(16.dp))

                val options = listOf("Yes", "No")

                options.forEach { option ->
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.padding(vertical = 8.dp)
                    ){
                        RadioButton(
                            selected = hasSteam == option,
                            onClick = { hasSteam = option }
                        )
                        Text(option)
                    }
                }
            }

        }



        Spacer(Modifier.height(16.dp)) //originally 40 see if i broke it w that

        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.padding(vertical = 8.dp)
        ){

            if (page > 0) {
                Button(onClick = { page-- }) {
                    Text("Back")
                }
            }

            Spacer(Modifier.width(16.dp))

            Button(onClick = {
                if (page < 17) page++
            }) {
                Text("Next")
            }


        }

    }

}