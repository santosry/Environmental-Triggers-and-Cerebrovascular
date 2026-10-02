# Fundamentação científica e referências

Este documento reúne as referências que sustentam **cada decisão metodológica** do
projeto. As referências são reais; os DOIs foram inseridos a partir de fontes
verificáveis (Crossref/editoras). Onde o DOI não é aplicável (ex.: livros, relatórios),
indica-se editora/URL.

---

## 1. Relato e condução de revisões sistemáticas

1. **Page MJ, McKenzie JE, Bossuyt PM, et al.** The PRISMA 2020 statement: an updated
   guideline for reporting systematic reviews. *BMJ*. 2021;372:n71.
   doi:10.1136/bmj.n71
   → Base do fluxo de identificação/seleção e do checklist de relato (`08_relatorios/`).

2. **Page MJ, Moher D, Bossuyt PM, et al.** PRISMA 2020 explanation and elaboration:
   updated guidance and exemplars for reporting systematic reviews. *BMJ*.
   2021;372:n160. doi:10.1136/bmj.n160

3. **Moher D, Shamseer L, Clarke M, et al.** Preferred reporting items for systematic
   review and meta-analysis protocols (PRISMA-P) 2015 statement. *Syst Rev*. 2015;4:1.
   doi:10.1186/2046-4053-4-1
   → Estrutura do protocolo (`01_protocolo/PROTOCOLO_REVISAO.md`).

4. **Higgins JPT, Thomas J, Chandler J, et al. (eds).** *Cochrane Handbook for
   Systematic Reviews of Interventions*. 2nd ed. Chichester: Wiley; 2019.
   doi:10.1002/9781119536604
   → Métodos de síntese, avaliação de risco de viés e certeza da evidência.

5. **Institute of Medicine.** *Finding What Works in Health Care: Standards for
   Systematic Reviews*. Washington, DC: National Academies Press; 2011.
   doi:10.17226/13111

## 2. Síntese quantitativa (meta-análise)

6. **Borenstein M, Hedges LV, Higgins JPT, Rothstein HR.** *Introduction to
   Meta-Analysis*. 2nd ed. Hoboken: Wiley; 2021.
   → Justificativa do modelo de **efeitos aleatórios** (assume que os estudos estimam
   efeitos distintos, com variabilidade entre estudos; recomendado quando a
   heterogeneidade clínica/metodológica é esperada, como em epidemiologia ambiental).

7. **Viechtbauer W.** Conducting meta-analyses in R with the metafor package.
   *J Stat Softw*. 2010;36(3):1-48. doi:10.18637/jss.v036.i03
   → Implementação (`metafor::rma`).

8. **Balduzzi S, Rücker G, Schwarzer G.** How to perform a meta-analysis with R: a
   practical tutorial. *Evid Based Ment Health*. 2019;22(4):153-160.
   doi:10.1136/ebmental-2019-300117
   → Implementação (`meta::metagen`, `metabin`, forest plots).

9. **Harrer M, Cuijpers P, Furukawa TA, Ebert DD.** *Doing Meta-Analysis with R:
   A Hands-On Guide*. Boca Raton: Chapman & Hall/CRC; 2021.
   doi:10.1201/9781003107347
   → Pacote `dmetar`, fluxo prático de meta-análise.

10. **Higgins JPT, Thompson SG.** Quantifying heterogeneity in a meta-analysis.
    *Stat Med*. 2002;21(11):1539-1558. doi:10.1002/sim.1186
    → **I²** e τ² como medidas de heterogeneidade.

11. **Higgins JPT, Thompson SG, Deeks JJ, Altman DG.** Measuring inconsistency in
    meta-analyses. *BMJ*. 2003;327(7414):557-560. doi:10.1136/bmj.327.7414.557
    → Interpretação prática de I².

12. **IntHout J, Ioannidis JPA, Rovers MM, Goeman JJ.** Plea for routinely presenting
    prediction intervals in meta-analysis. *BMJ Open*. 2016;6(7):e010247.
    doi:10.1136/bmjopen-2015-010247
    → **Intervalo de predição** além do IC95% do efeito médio.

13. **Hartung J, Knapp G.** A refined method for the meta-analysis of controlled clinical
    trials with binary outcome. *Stat Med*. 2001;20(24):3875-3889.
    doi:10.1002/sim.1009

14. **IntHout J, Ioannidis JPA, Borm GF.** The Hartung-Knapp-Sidik-Jonkman method for
    random effects meta-analysis: a simple method for accurate and robust meta-analysis
    with few studies. *BMC Med Res Methodol*. 2014;14:25. doi:10.1186/1471-2288-14-25
    → Método **HK/SJ** para número pequeno de estudos.

15. **Hedges LV, Vevea JL.** Fixed- and random-effects models in meta-analysis.
    *Psychol Methods*. 1998;3(4):486-504. doi:10.1037/1082-989X.3.4.486

## 3. Viés de publicação e de pequenos estudos

16. **Egger M, Davey Smith G, Schneider M, Minder C.** Bias in meta-analysis detected by
    a simple, graphical test. *BMJ*. 1997;315(7109):629-634.
    doi:10.1136/bmj.315.7109.629
    → **Teste de Egger**.

17. **Duval S, Tweedie R.** Trim and fill: a simple funnel-plot-based method of testing
    and adjusting for publication bias in meta-analysis. *Biometrics*. 2000;56(2):455-463.
    doi:10.1111/j.0006-341x.2000.00455.x
    → **Trim-and-fill**.

18. **Sterne JAC, Sutton AJ, Ioannidis JPA, et al.** Recommendations for examining and
    interpreting funnel plot asymmetry in meta-analyses of randomised controlled trials.
    *BMJ*. 2011;343:d4002. doi:10.1136/bmj.d4002
    → Regras para interpretar funil (estudos ≥10; ajuste por heterogeneidade).

19. **Begg CB, Mazumdar M.** Operating characteristics of a rank correlation test for
    publication bias. *Biometrics*. 1994;50(4):1088-1101. doi:10.2307/2533446

## 4. Risco de viés e qualidade metodológica

20. **Sterne JAC, Hernán MA, Reeves BC, et al.** ROBINS-I: a tool for assessing risk of
    bias in non-randomised studies of interventions. *BMJ*. 2016;355:i4919.
    doi:10.1136/bmj.i4919
    → Domínios de confusão, seleção, classificação da exposição/desfecho, dados
    faltantes e relato seletivo, para coortes/caso-controle.

21. **Wells GA, Shea B, O'Connell D, et al.** *The Newcastle-Ottawa Scale (NOS) for
    assessing the quality of nonrandomised studies in meta-analyses*. Ottawa: Ottawa
    Hospital Research Institute; 2000.
    https://www.ohri.ca/programs/clinical_epidemiology/oxford.asp
    → Escala para coortes e caso-controle.

22. **McGuinness LA, Higgins JPT.** Risk-of-bias VISualization (robvis): an R package and
    Shiny web app for visualizing risk-of-bias assessments. *Res Synth Methods*.
    2021;12(1):55-61. doi:10.1002/jrsm.1411
    → Figuras "traffic light" e "summary" do risco de viés.

23. **Office of Health Assessment and Translation (OHAT), NTP.** *OHAT Risk of Bias
    Rating Tool for Human and Animal Studies*. Research Triangle Park: NIEHS; 2015.
    https://ntp.niehs.nih.gov/whatwestudy/assessments/noncancer/riskbias
    → Ferramenta orientada a exposições ambientais (confundimento, exposição,
    desfecho, atrito, detecção, relatividade).

24. **Schünemann H, Brożek J, Guyatt G, Oxman A (eds).** *GRADE Handbook for Grading
    Quality of Evidence and Strength of Recommendations*. 2013.
    https://gdt.gradepro.org/app/handbook/handbook.html
    → Certeza da evidência (domínios: risco de viés, inconsistência, evidência indireta,
    imprecisão, viés de publicação).

25. **Guyatt GH, Oxman AD, Vist GE, et al.** GRADE: an emerging consensus on rating
    quality of evidence and strength of recommendations. *BMJ*. 2008;336(7650):924-926.
    doi:10.1136/bmj.39489.470347.AD

## 5. Exposição ambiental, clima e doenças cerebrovasculares

26. **Gasparrini A.** Distributed lag linear and non-linear models in R: the package
    dlnm. *J Stat Softw*. 2011;43(8):1-20. doi:10.18637/jss.v043.i08
    → Modelos de defasagem distribuída (DLNM), quando aplicável a exposições agudas.

27. **Gasparrini A, Guo Y, Hashizume M, et al.** Mortality risk attributable to high and
    low ambient temperature: a multicountry observational study. *Lancet*.
    2015;386(9991):369-375. doi:10.1016/S0140-6736(14)62114-0
    → Tratamento de exposições térmicas agudas vs. crônicas; curvas em U/J.

28. **Perkins SE, Alexander LV.** On the measurement of heat waves. *J Clim*.
    2013;26(13):4500-4517. doi:10.1175/JCLI-D-12-00383.1
    → Definição de onda de calor (percentil + duração mínima).

29. **World Meteorological Organization (WMO).** *Guidelines on the Definition and
    Monitoring of Extreme Weather and Climate Events*. Geneva: WMO; 2018.
    → Definições operacionais de eventos extremos.

30. **World Health Organization.** *WHO global air quality guidelines: particulate matter
    (PM2.5 and PM10), ozone, nitrogen dioxide, sulfur dioxide and carbon monoxide*.
    Geneva: WHO; 2021. ISBN 978-92-4-003422-8.
    → Métricas e limites de poluentes do ar.

31. **Feigin VL, Stark BA, Johnson CO, et al.** Global, regional, and national burden of
    stroke and its risk factors, 1990–2019: a systematic analysis for the Global Burden
    of Disease Study 2019. *Lancet Neurol*. 2021;20(10):795-820.
    doi:10.1016/S1474-4422(21)00252-0
    → Magnitude global do AVC e relevância dos fatores ambientais modificáveis.

32. **Wolf J, Prüss-Ustün A, Cumming O, et al.** Assessing the impact of drinking water
    and sanitation on diarrhoeal disease in low- and middle-income settings: systematic
    review and meta-regression. *Trop Med Int Health*. 2014;19(8):928-942.
    doi:10.1111/tmi.12331
    → Método de meta-regressão para exposições ambientais (adaptável).

33. **Prüss-Ustün A, Wolf J, Corvalán C, Bos R, Neira M.** *Preventing Disease Through
    Healthy Environments: A Global Assessment of the Burden of Disease from
    Environmental Risks*. Geneva: WHO; 2016. ISBN 978-92-4-156537-0.

34. **Landrigan PJ, Fuller R, Acosta NJR, et al.** The Lancet Commission on pollution and
    health. *Lancet*. 2018;391(10119):462-512. doi:10.1016/S0140-6736(17)32345-0
    → Enquadramento de exposições ambientais e desfechos cardiovasculares.

## 6. Classificação do desfecho

35. **World Health Organization.** *ICD-10: International Statistical Classification of
    Diseases and Related Health Problems, 10th revision*. Geneva: WHO; 1992.
    → Definição dos códigos I60–I69 (hemorragia subaracnóidea; hemorragia intracerebral;
    infarto cerebral; AVC não especificado; oclusão/estenose de artérias pré-cerebrais e
    cerebrais; outras doenças cerebrovasculares; transtornos cerebrovasculares em doenças
    classificadas em outra parte; sequelas).

## 7. Ferramentas de software

36. **Aria M, Cuccurullo C.** bibliometrix: An R-tool for comprehensive science mapping
    analysis. *J Informetr*. 2017;11(4):959-975. doi:10.1016/j.joi.2017.08.007

37. **Grames EM, Stillman AN, Tingley MW, Elphick CS.** litsearchr: Automated search term
    selection and search strategy for systematic reviews. *J Open Source Softw*.
    2019;4(36):1160. doi:10.21105/joss.01160

38. **Haddaway NR, Pritchard CC, McGuinness LA.** PRISMA2020: An R package and Shiny app
    for producing PRISMA 2020-compliant flow diagrams. *Campbell Syst Rev*.
    2022;18(2):e1230. doi:10.1002/cl2.1230

39. **McGrath S, Zhao X, Steele R, et al.** metaDigitise: extract data from figures.
    *Methods Ecol Evol*. 2019;10(2):204-210. doi:10.1111/2041-210X.13101

40. **Ouzzani M, Hammady H, Fedorowicz Z, Elmagarmid A.** Rayyan—a web and mobile app for
    systematic reviews. *Syst Rev*. 2016;5:210. doi:10.1186/s13643-016-0384-4
    → Triagem por dois revisores.

41. **Sutton A, Graña DR, Haddaway NR, et al.** *PRISMA2020* / *revtools* — apoio à
    deduplicação e triagem automatizada.
    - **Westgate MJ.** revtools: An R package to support article screening for evidence
      synthesis. *Res Synth Methods*. 2019;10(4):606-614. doi:10.1002/jrsm.1374

## 8. Escalas de medida de efeito

42. **Rothman KJ, Greenland S, Lash TL.** *Modern Epidemiology*. 3rd ed. Philadelphia:
    Lippincott Williams & Wilkins; 2008.
    → Escolha entre RR, OR, HR e interpretação conforme o desenho (coorte → RR/HR;
    caso-controle → OR; séries temporais → excesso relativo por incremento).

43. **VanderWeele TJ, Ding P.** Sensitivity analysis in observational research:
    introducing the E-value. *Ann Intern Med*. 2017;167(4):268-274.
    doi:10.7326/M16-2607
    → Análise de sensibilidade para confundimento não medido.

---

## Como citar este projeto

```
Santos RP, Nunes CH, et al. Environmental determinants of cerebrovascular diseases
(ICD-10 I60–I69) across the lifespan: a global systematic review and meta-analysis.
Protocol; 2026.
```
