# Coursework and projects

I study BSc Intelligent Systems at the Technical University of Košice (TUKE), 2024 to 2027, with an exchange semester at the University of Eastern Finland (UEF) in autumn 2026. This repository collects my reports, code and slides from university courses. Each course has its own folder, and larger projects live in separate repositories.

Reports are written in English or Slovak. Slovak ones are marked "(SK)".

## Featured projects

| Project | Context | What it shows | Links |
|---|---|---|---|
| Speech emotion recognition with a 2D CNN | Neural Networks, team of four | A research-style paper with ablation, noise tests, transfer learning and Grad-CAM. The CNN reaches 61.89% macro F1 on CREMA-D. My part was the manuscript, the CREMA-D experiments and the repository structure. | [Paper](Neural%20Networks/speech-emotion-recognition-report.pdf), [slides](Neural%20Networks/speech-emotion-recognition-slides.pptx), [code](https://github.com/kassxxv/speech-emotion-recognition-using-cnn) |
| Bridgy | Junction 2026 hackathon | A web application that selects candidates for 1:1 meetings at recruitment events in one blind table. Built with Next.js, Gemini and a self-hosted Gemma 3 model. | [Code](https://github.com/kassxxv/junction-2026-lafa), [live demo](https://junction-2026-lafa.vercel.app) |
| ID3 decision tree generator | Machine Learning | ID3 implemented from scratch, with a Flask and D3.js web interface for uploading CSV files and viewing trees. | [Code](https://github.com/kassxxv/id3-gen-of-decision-trees) |

## By topic

| Topic | Work |
|---|---|
| Machine learning and deep learning | [Speech emotion recognition](Neural%20Networks/speech-emotion-recognition-report.pdf), [hyperparameter testing on CIFAR-10](Neural%20Networks/hyperparameter-testing-report.pdf), [crime-rate regression](Artificial%20Intelligence/crime-regression-report.pdf), [MLP regression](Artificial%20Intelligence/crime-mlp-report.pdf), [ID3 decision trees](https://github.com/kassxxv/id3-gen-of-decision-trees) |
| Algorithms and optimisation | [Greedy heuristics](Heuristic%20Optimization/greedy-heuristics-report.pdf), [CP-SAT scheduling](Heuristic%20Optimization/cp-sat-scheduling-report.pdf), [minimax search](Artificial%20Intelligence/minimax-code.py) |
| Software and databases | [Bridgy web application](https://github.com/kassxxv/junction-2026-lafa), [Oracle test management database](Application%20of%20Database%20Systems/software-test-management-db-report.pdf) |
| Electronics and embedded systems | Air quality prototype with gas sensors and a compact PLC (Internet of Things), Electrical Engineering |
| 3D modelling and human-computer interaction | [3D print model](Digital%20Transformation%20and%20Industry%205.0/3d-print-sofa-2-model.stl), Eye Tracking at UEF (autumn 2026) |
| Mathematics and physics | Mathematics I to III, Numerical Mathematics, Probability and Statistics, Physics |

## Year 3, autumn 2026

This semester I am on exchange at UEF, taking four courses there and one at TUKE. I may attach my work from these courses after the semester.

| Course | Where | Topics |
|---|---|---|
| Advanced Deep Learning | UEF | Deep neural network architectures, training and evaluation beyond the basics |
| Eye Tracking | UEF | Eye-tracking hardware, running a small study and analysing gaze data |
| Robotics | UEF | Introduction to robotics |
| Learning Analytics | UEF | Collecting and analysing data about learners and learning |
| Actual Trends in Intelligent Systems | TUKE | Current topics in intelligent systems |

Planned for spring 2027: Computer Vision, Cloud Technologies, and Social Sciences and Technology.

## Year 2 (2025/26)

| Course | Work |
|---|---|
| Machine Learning | ID3 decision tree generator. Builds trees from uploaded CSV files in a Flask and D3.js web interface. [Code](https://github.com/kassxxv/id3-gen-of-decision-trees) |
| Neural Networks | Speech emotion recognition with a 2D CNN, written with three coauthors. Compares log-mel and MFCC features on CREMA-D and RAVDESS. Transfer from CREMA-D raises RAVDESS from 38.14% to 44.97%. [Paper](Neural%20Networks/speech-emotion-recognition-report.pdf), [slides](Neural%20Networks/speech-emotion-recognition-slides.pptx), [code](https://github.com/kassxxv/speech-emotion-recognition-using-cnn) |
| | Hyperparameter testing of an MLP on CIFAR-10 in PyTorch. A greedy search over topology, optimiser, learning rate, activation and regularisation, with three seeds. The final model reaches 48.02% test accuracy against 30.49% for logistic regression. [Report](Neural%20Networks/hyperparameter-testing-report.pdf), [code](Neural%20Networks/hyperparameter-testing-code.py), [assignment (SK)](Neural%20Networks/hyperparameter-testing-assignment.pdf) |
| Artificial Intelligence | Regression on the Communities and Crime dataset (1994 samples, 122 features). Compares five scikit-learn regressors, and Random Forest is best with R² 0.6424. [Report (SK)](Artificial%20Intelligence/crime-regression-report.pdf), [notebook](Artificial%20Intelligence/crime-regression-notebook.ipynb) |
| | MLP regression on the same dataset at four train and test splits. R² is 0.50 at the 70/30 split, against 0.63 for Random Forest. [Report (SK)](Artificial%20Intelligence/crime-mlp-report.pdf), [notebook](Artificial%20Intelligence/crime-mlp-notebook.ipynb) |
| | Systematic literature review of computational humor generation and detection, written with four coauthors. [Paper](Artificial%20Intelligence/humor-review-report.pdf), [slides](Artificial%20Intelligence/humor-review-slides.pptx) |
| | Minimax search on a 16-leaf game tree in Python. [Code](Artificial%20Intelligence/minimax-code.py) |
| | Iris dataset lab answers covering an MLP, fuzzy c-means, a Mamdani system and a genetic algorithm. [Notes (SK)](Artificial%20Intelligence/iris-fuzzy-ga-notes.txt) |
| | [Video (SK)](https://youtu.be/mo3ToQiF-_E) |
| Heuristic Optimization | Greedy heuristics, written with three teammates. Compares four activity selection strategies, and greedy against dynamic programming for coin change. Earliest finish time is optimal, and greedy fails on some coin systems. [Report (SK)](Heuristic%20Optimization/greedy-heuristics-report.pdf), [code](Heuristic%20Optimization/greedy-heuristics-code.py) |
| | Process scheduling with Google OR-Tools CP-SAT, written with three teammates. [Report (SK)](Heuristic%20Optimization/cp-sat-scheduling-report.pdf), [code](Heuristic%20Optimization/cp-sat-scheduling-code.zip) |
| Application of Database Systems | Oracle database for software development and test management. [Report (SK)](Application%20of%20Database%20Systems/software-test-management-db-report.pdf), [SQL](Application%20of%20Database%20Systems/software-test-management-db-code.sql), [ER diagram](Application%20of%20Database%20Systems/software-test-management-db-er-diagram.png), [schema](Application%20of%20Database%20Systems/software-test-management-db-schema-diagram.png) |
| Digital Transformation and Industry 5.0 | Slides on the Siemens Healthineers digital twin at Mater Hospital Dublin, which raised MRI capacity by 32% and CT capacity by 26%. [Slides (SK)](Digital%20Transformation%20and%20Industry%205.0/digital-twins-siemens-healthineers-slides.pdf) |
| | A sofa scene modelled in Tinkercad and sliced in PrusaSlicer for 3D printing. [Model](Digital%20Transformation%20and%20Industry%205.0/3d-print-sofa-2-model.stl), [slicer screenshot](Digital%20Transformation%20and%20Industry%205.0/3d-print-sofa-3-slicer-screenshot.jpg) |
| Internet of Things | Air quality prototype with gas sensors that shows the health of the air, with a deployed web interface. The team deployed it with Azure and AWS and worked with a compact PLC. I designed the concept, the system and the web interface, and wired the hardware with the team. |
| | Written tests on digital-to-analog and analog-to-digital conversion formulas and on Karnaugh maps. |
| Other courses | Mathematics III, Numerical Mathematics, Probability and Statistics, Databases, Application of Web Technologies |

## Year 1 (2024/25)

| Course | Work |
|---|---|
| Introduction to Intelligent Systems | Network basics in Cisco Packet Tracer. |
| | Elements of AI, a 2 ECTS online course by the University of Helsinki and MinnaLearn. [Slovak version, March 2025](Introduction%20to%20Intelligent%20Systems/elements-of-ai-sk-certificate.png) and [English version, November 2026](Introduction%20to%20Intelligent%20Systems/elements-of-ai-certificate.png). |
| | MATLAB courses from April and May 2025: [MATLAB Onramp](Introduction%20to%20Intelligent%20Systems/matlab-onramp-certificate.pdf), [Simulink Onramp](Introduction%20to%20Intelligent%20Systems/simulink-onramp-certificate.pdf) and [Introduction to Symbolic Math](Introduction%20to%20Intelligent%20Systems/matlab-symbolic-math-certificate.pdf). |
| Other courses | Mathematics I and II, Introduction to Engineering, Fundamentals of Algorithms and Programming, Programming, Python, Physics, Electrical Engineering |

## Other projects

[Python test automation course](https://github.com/kassxxv/aqa-course-hillel): homework from the Hillel School course, from the basics to full automated tests.
