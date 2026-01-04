# KV25 CANDIDATE TEST

*Exploring political landscape of Copenhagen municipality using*

***Gifi** library and **PRINCALS** method in **R**.*

# EXECUTIVE SUMMARY

This is an alternative method for finding your top candidates and parties in municipal elections:

![][image9]

* Maps all the candidates and shows how you compare to all of them in terms of  overall response patterns.  
* Allows to apply a hard filter on important questions  
* Shows visually which parties, candidates and possible mayors align with you the most.

Caveats:

* Tricky scale interpretation, needs many disclaimers in order to stay non-speculative.  
* Needs a lot of candidates with complete surveys and different enough answers to give meaningful results.

Next steps

* Making it an interactive app  
* Adding a BERT model for Key Issues summary

# PREFACE

In November 2025 I got to vote in the Copenhagen Kommunalvalg for the first time. As an international I only knew the 2 biggest parties in the Folketing, but didn’t know much about the municipal political landscape, so didn’t know whom I should choose out of 262 candidates.

For people like me several Danish news outlets ([DR](https://www.dr.dk/nyheder/politik/kommunalvalg/kandidattest), [TV2](https://nyheder.tv2.dk/kandidattest) and [Altinget](https://www.altinget.dk/kandidattest/KV25)) offered Candidate tests that had 19 \- 28 questions on the most popular issues with 4- or 5-scale Likert scale replies. 

![][image1]

Once completed, the sites calculate a distance between your answers and all the candidates and suggest top 3 candidates based on your overall agreement.

I completed several tests, but wasn’t convinced with the results, as I got different recommended parties on all the platforms.

# HYPOTHESIS & METHODS

According to the websites, all the tests used **weighted distance-based methods** (Euclidean or Manhattan) which are easy to reproduce and interpret, and work well with any number of candidates, but have some weaknesses:

* They assume equal “distance” between neighbouring responses.  
* Some topics have more questions dedicated to them, so they effectively outweigh the rest in the final calculation.

Principal component analysis caveats:

* Pros  
  * Handles question redundancies and measures latent traits rather than individual questions.  
  * Doesn't assume linear and equal distances between the answers, rescales the scores to maximise the variance.  
* Cons  
	* Very relative, to averages and requires a large number of candidates.  
	* Still doesn’t adjust to personal response patterns (all strong vs all neutrals)

# DATA & CAVEATS

I took the DR test data with a 4-point scale that omits the ‘Neutral’ and helps to get a better understanding on the range of neutral opinions.

The dataset has 261 candidates and their responses for 19 questions. 

Data caveats:

- **Missing data**: some candidates had 1-4 missing answers, some didn’t complete the survey at all. For the purposes of this analysis I **excluded 39 candidates** that had incomplete surveys.  
- **Translating Likert scale into numeric** is not straightforward because the perceived distance between responses can be different, and some questions are more divisive than the others.

# PRINCALS ANALYSIS

## Assigning initial numeric values

| Disagree | Somewhat disagree | Somewhat agree | Agree |
| :---: | :---: | :---: | :---: |
| \-1 | \-0.5 | 0.5 | 1 |

For the simplicity of the analysis I picked standard initial values that have opposite signs meaning directional agreement or disagreement with questions. 

## Question list

\*KK stands for Københavns Kommune (Municipality of Copenhagen).

| \# | Question |
| :---- | :---- |
| 1 | More tasks in the public sector should be handled by private companies in the future. |
| 2 | Public institutions take too many precautions for religious minorities, for example by offering meals without pork. |
| 3 | Investment in the road network is more urgent than investment in public transport. |
| 4 | It is possible to save money in the public sector without compromising public welfare. |
| 5 | The municipal tax in KK should be increased and the money must be spent on better welfare. |
| 6 | KK should make it cheaper to do business. |
| 7 | More renewable energy plants such as wind turbines and solar cells should be installed in KK. |
| 8 | KK should ensure a lunch program in primary schools, even if it may take money from other tasks. |
| 9 | KK should ensure usable shelters, even if it may mean less money for other areas. |
| 10 | Elderly people should be able to purchase extra services at municipal nursing homes. |
| 11 | KK should prioritize that school students are mixed according to ethnicity and social background – even if this may affect parents' free choice of school. |
| 12 | There should be higher fees for cultural and leisure facilities such as theaters, youth clubs and library events. |
| 13 | More parking spaces should be established in KK. |
| 14 | Politicians should prevent the construction of mosques. |
| 15 | KK should promote the construction of more public rental housing. |
| 16 | Too many high-rise buildings are being built. |
| 17 | KK must establish emergency schools for students who have been transgressive or violent towards classmates or teachers. |
| 18 | The upcoming artificial peninsula Lynetteholm is an important part of the development of Copenhagen. |
| 19 | It is a good idea to close down parking spaces in the center of Copenhagen. |

## Running PRINCALs analysis

**PRINCALs** is an iterative function that treats the numeric scores as ordinal, runs the Principal Component Analysis on them and evaluates how well the resulting components explain the variation in the dataset. Based on the evaluation, these scores are adjusted to better fit the component structure while preserving the original order. The process is repeated iteratively, and stops when category values and explained variance stabilize and  further iterations do not meaningfully improve the PCA solution. In my case it took 16 iterations.

![][image2]

*Fig 1: Scores on Principal Component 1* 

In the chart above you can see that Question 7 (adding more solar cells) is not very divisive and there is no difference between the candidates who answered ‘Disagree’ and ‘Somewheat disagree’ when it comes to explained variance. However, Question 18 (supporting construction of Lynetteholmen) shows the opposite behaviour: candidates that answered ‘Disagree’ are very different from those who answered ‘Somewhat disagree’.

## Selecting the number of Principal components for plotting

![][image3]

*Fig 2: Variance explained by each Principal Component*

Principal component 1 explains almost 50% of the variance. I will take **3 PCs** into account that will together **explain 65,4% of response variance**. 

I will take 2 components for the plot (PC1 and PC2) and keep the third (PC3) to get additional context during interpretation.

## 

## Interpreting the components 

* #### PC1 vs PC2

  ![][image4]

*Fig 3: Loadings chart PC1 vs PC2*

The loadings chart shows that there are clusters of questions that measure the same thing:

* Q1 (privatization of welfare) and Q6 (deregulating business) have parallel vectors, and q5 (increasing taxes) and Q15 (investing in social housing) are almost parallel to them facing the opposite direction, which suggest that the purple axis measures the focus on **public vs private sector**.  
* Q9 (preparing shelters)  is almost orthogonal to this axis which means that it’s **marginally affected by traditional political alignment**. 

Other insights from the dataset:

* Candidates that agree with Q13 (adding more parking spaces) are likely to agree with Q14 (preventing construction of mosques)   
* While those who agree with Q7 (adding solar panels) are also likely to agree with Q8 (ensuring free school meals)

* #### PC2 vs PC3

Since PC1 explains 50% of the variance, I will extract the residuals from PC2 and PC3 to see their loadings without the influence from PC1 to see which questions matter the most.

![][image5]

*Fig 4: Residual loadings,  PC2 vs PC3 controlled for PC1*

* PC3 is defined by disagreement with the statement that there are too many high-rise buildings (q16).  
* Top contributors to D2 are  
  * Agreement with the need to prepare shelters (q9).  
  * Disagreement with increasing prices for leisure centers (q12).  
  * Disagreement with closing down central parking spaces (q19).

  These questions are thematically different, so there is **no clear non-speculative way to describe it**.  

  Agreement with q12 and q19 would generally mean belonging to different general alignments (private vs public). However, both q12 and q19 represent the extreme ends of each alignment,  while q9 represents mainstream European concerns about possible emergencies. Therefore, I could loosely **interpret PC2** as measuring **radical vs mainstream** end within each camp. Another way to contextualise these questions would be **youth vs family orientation**, as people who have kids are more likely to care about the leisure centers, parking spaces and organized shelters in case of emergencies.

## Rotating the axes 

To better understand my position on PC1 vs PC2, I will rotate the coordinates to make sure that the main ideological vector is horizontal, and all the socialist-leaning parties are on the left to make it more intuitive.

![][image6]

*Fig 5: New rotates coordinates*

**Note**: this left vs right division is very relative to the question phrasing and average responses. Denmark is a welfare state, and even ‘right-leaning’ parties in Denmark could be still considered centrist, or center-left outside of this sample.

# RESULTS

## DR test result

![][image7]

*Fig 6: My top candidates according to the DR Candidate test*

The test from DR suggests that most of my top candidates are from **Radikale Venstre** with one from **Alternativet**.

* A little noise: it’s clear that most parties have internal consensus about most issues, so the results are likely to be populated with the same party.  
* While they do agree on most questions, some of them disagree on the ones most important to me.

## 

## PRINCALS results

To visualize the results I took the rotated PC1 and PC2.

**Note**: the horizontal axis (PC1) appears stretched to show the variance.

![][image8]

*Fig 7: Mapping major parties. Bigger dots represent \#1 party candidates.* 

As I concluded before, there is no clear way to describe PC2 without over-simplifying it. Therefore, I will label it as just PC2. Candidates scoring higher on this axis tend to share more of the following views:

* Copenhagen must ensure usable shelters.  
* There should be ‘akutsoler’ for students who have been violent towards classmates.  
* The municipality should prevent construction of mosques.  
* There should be more parking spaces.  
* The city should not close more parking spaces in the city center.  
* Prices for theaters and museums should not be increased. 


Key insights from the chart:

* Clear red and blue blocks with several overlapping parties showing overall agreements between major parties and most likely coalitions.  
* Parties with the least overlap:  
  * **Socialdemokratiet**: center-left on ‘Welfare vs Business’,  highest on PC2.   
  * **Liberal Alliance**: the most business-focused, lowest on PC2.  
  * **Radikale Venstre**: centrist on PC1, low on PC2.  
* **Enhedslisten** seems to have the highest agreement within the party, as their cluster is the least spread-out.  
* Number one candidates from every major party (bigger dots) seem to be the most radical compared to other candidates from their parties (both left and right).

Top 6 candidates considering all 3 PCs (including depth):

| Cand\_id, Distance | Issue 1 topic | Issue 2 topic | Issue 3 topic |
| :---- | :---- | :---- | :---- |
| V\_3 0.21 | Metro to Valby and Nordvest | Allow outdoor dining | Investing in leisure centers |
| B\_9 0.38 | Climate and green transition: coastal protection \+ green and public transport. | New green areas in the urban space | Coastal protection of Amager |
| B\_1 0.39 | Converting rooftops and empty commercial buildings into 10,000 new apartments | 15 new open spaces in the city | Coastal protection of Amager |
| B\_6 0.42 | Children’s wellbeing | Balancing parking, public transport, bikes and electric cars | Anti-discrimination |
| V\_16 0.64 | Less bureaucracy for businesses | Optimising public transport  \+ metro to Bispebjerg and Bellahøj | Converting empty and underused buildings into housing |
| V\_5 0.64 | More green urban areas | Building more apartments, allowing them to be smaller | Optimising public transport  \+ parking |

Just like DR’s test, my test predicts top candidates from **Radikale Venstre** and **Venstre**.

Although the candidate ids are different, overall there seems to be no big difference in the results predicted by PRINCALS and distance-based bethods.

However, I’m still not convinced because of 19 questions there are only 2 that I really care about, and most top candidates that were suggested by both methods disagree with 1 or 2 of them.

## 

## PRINCALS \- filter on important questions

I introduced the ‘Important question filter’. This filter takes a list of the questions that are especially important to me and checks whether a candidate directionally agrees with me on them. 

For example, if I chose Q1 as important and selected ‘Agree’ as my response, all candidates who answered ‘Agree’ or ‘Somewhat agree’ would pass the filter.

![][image9]

*Fig 8: PRINCALS mapping the filter on important questions (• pass the filter, ✖ don’t).*

After applying the filter I can see more clearly 3 things about the important questions:

- what candidates agree with me  
- what party leaders agree with me (bigger dots)  
- what parties have the highest share of members who agree with me

This information is relevant because in case I vote for a candidate and they don’t get enough votes to get a seat, my vote will be counted towards the party, and most likely the first 5 candidates on their lists. 

Looking at this chart, I can see that my closest match is from **Det Konservative Folkeparti**, but they appear to be an outlier, as no other candidate from this party passes the filter. I can also see that my safest party choices are **Enhedslisten**, **Socialistisk Folkeparti**.

On another hand, if I see that none of my nearest neighbours agree with me on important questions, I can check their comments, see why they replied a certain way and possibly still give them a vote.

Top 6 candidates who pass the filter:

| Cand\_id, Distance | Issue 1 topic | Issue 2 topic | Issue 3 topic |
| :---- | :---- | :---- | :---- |
| C\_14 1.15 | Clean drinking water | Flood protection | Investing in leisure centers |
| B\_7 1.21 | New family housing, especially in Nordvest | Fast-Track on the bike lanes | More green areas \+ metro to Nordvest and Bronshøj |
| T\_3 1.34 | Preserving liberal left-wing values | Legilise cannabis | Better psychiatric diagnostics |
| Ø\_19 1.43 | More public and cooperative housing | Supporting economically disadvantaged | Support for volunteer organisations |
| Å\_9 1.45 | Stop the Lynetteholm project | Better conditions for pedestrians and handicapped | More freedom for local councils and committees. |
| B\_12 1.48 | Treatment guarantee for depression | Psychiatric care | More solar cells on the rooftops |

Although these candidates agree with me on the questions that were included in the survey, looking at the Key Issues, I can’t see anything that picks my interest. 

As an international who lives on Amager, I won’t directly benefit from public housing, metro to Nordvest. Legalising cannabis is also not among my top 3 priorities.

# CONCLUSION

Although PRINCALs is very visual and fun to use, it still didn’t solve my problem:

* The unfiltered results were practically the same as the ones from distance-based methods used on DR’s site. If you don’t know the political landscape the chart is still useful, but if you do the difference in results is small.  
* Axes interpretation can be tricky, as several vectors may strongly correlate while being thematically unrelated (i.e. solar cells and free school lunches).  
* The filtered results provide the most value, as they highlight the parties with the largest share of candidates that agree with you.

I think that regardless of the method chosen, the survey alone can’t be a good basis for finding the best match for several reasons:

* The survey questions are limited to the most popular ones  
* The answers don’t reflect the Key Issues declared by the parties and candidates  
* It can be easy to miss a candidate who is ready to prioritise the issues that are niche but really important to you personally (i.e.rent control, specific neighborhoods, etc) behind the noise of the survey.

# NEXT STEPS

As a voter, I could really benefit from a searchable summary of the key issues and comments to the survey answers to find the candidates and parties that want to focus on something important to me personally, but possibly not popular enough to be added in the survey.

As the next step of my project I will:

1. Train a BERT model to analyse the Key Issues and comments to find  
   1. Response patterns and overlap  
   2. Niche Key Issues  
2. Make a responsive Shiny app

[image1]:images/likert.png
[image2]:images/transplot.png
[image3]:images/scree_plot.png
[image4]:images/pc1_pc2.png
[image5]:images/pc2_pc3.png
[image6]:images/pc1_pc2_rot.png
[image7]:images/dr_result.png
[image8]:images/princals_all.png
[image9]:images/princals_filter.png
[image8]:images/princals_all.png
[image9]:images/princals_filter.png
