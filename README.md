------------------------------------------------------------------------------------------------------
ATELIER API-DRIVEN INFRASTRUCTURE
------------------------------------------------------------------------------------------------------
L’idée en 30 secondes : **Orchestration de services AWS via API Gateway et Lambda dans un environnement émulé**.  
Cet atelier propose de concevoir une architecture **API-driven** dans laquelle une requête HTTP déclenche, via **API Gateway** et une **fonction Lambda**, des actions d’infrastructure sur des **instances EC2**, le tout dans un **environnement AWS simulé avec LocalStack** et exécuté dans **GitHub Codespaces**. L’objectif est de comprendre comment des services cloud serverless peuvent piloter dynamiquement des ressources d’infrastructure, indépendamment de toute console graphique.Cet atelier propose de concevoir une architecture API-driven dans laquelle une requête HTTP déclenche, via API Gateway et une fonction Lambda, des actions d’infrastructure sur des instances EC2, le tout dans un environnement AWS simulé avec LocalStack et exécuté dans GitHub Codespaces. L’objectif est de comprendre comment des services cloud serverless peuvent piloter dynamiquement des ressources d’infrastructure, indépendamment de toute console graphique.
  
-------------------------------------------------------------------------------------------------------
Séquence 1 : Codespace de Github
-------------------------------------------------------------------------------------------------------
Objectif : Création d'un Codespace Github  
Difficulté : Très facile (~5 minutes)
-------------------------------------------------------------------------------------------------------
RDV sur Codespace de Github : <a href="https://github.com/features/codespaces" target="_blank">Codespace</a> **(click droit ouvrir dans un nouvel onglet)** puis créer un nouveau Codespace qui sera connecté à votre Repository API-Driven.
  
---------------------------------------------------
Séquence 2 : Création de l'environnement AWS (LocalStack)
---------------------------------------------------
Objectif : Créer l'environnement AWS simulé avec LocalStack  
Difficulté : Simple (~5 minutes)
---------------------------------------------------

Dans le terminal du Codespace copier/coller les codes ci-dessous etape par étape :  

**Installation de l'émulateur LocalStack**  
```
sudo -i mkdir rep_localstack
```
```
sudo -i python3 -m venv ./rep_localstack
```
```
sudo -i pip install --upgrade pip && python3 -m pip install localstack && export S3_SKIP_SIGNATURE_VALIDATION=0
```
Rendez-vous chez Localstack pour vous créez un Token : https://app.localstack.cloud/
```
localstack auth set-token <YOUR_AUTH_TOKEN>
localstack start -d
```
**vérification des services disponibles**  
```
localstack status services
```
**Réccupération de l'API AWS Localstack** 
Votre environnement AWS (LocalStack) est prêt. Pour obtenir votre AWS_ENDPOINT cliquez sur l'onglet **[PORTS]** dans votre Codespace et rendez public votre port **4566** (Visibilité du port).
Réccupérer l'URL de ce port dans votre navigateur qui sera votre ENDPOINT AWS (c'est à dire votre environnement AWS).
Conservez bien cette URL car vous en aurez besoin par la suite.  

Pour information : IL n'y a rien dans votre navigateur et c'est normal car il s'agit d'une API AWS (Pas un développement Web type UX).

---------------------------------------------------
Séquence 3 : Exercice
---------------------------------------------------
Objectif : Piloter une instance EC2 via API Gateway
Difficulté : Moyen/Difficile (~2h)
---------------------------------------------------  
Votre mission (si vous l'acceptez) : Concevoir une architecture **API-driven** dans laquelle une requête HTTP déclenche, via **API Gateway** et une **fonction Lambda**, lancera ou stopera une **instance EC2** déposée dans **environnement AWS simulé avec LocalStack** et qui sera exécuté dans **GitHub Codespaces**. [Option] Remplacez l'instance EC2 par l'arrêt ou le lancement d'un Docker.  

**Architecture cible :** Ci-dessous, l'architecture cible souhaitée.   
  
![Screenshot Actions](API_Driven.png)   
  
---------------------------------------------------  
## Processus de travail (résumé)

1. Installation de l'environnement Localstack (Séquence 2)
2. Création de l'instance EC2
3. Création des API (+ fonction Lambda)
4. Ouverture des ports et vérification du fonctionnement

## 🛠️ Processus de travail (détaillé)

Afin de répondre aux exigences de l'atelier et d'assurer un déploiement reproductible, le travail a été structuré selon les quatre étapes suivantes :

**1. Installation de l'environnement Localstack (Séquence 2)**
* **Préparation du Codespace :** Création et initialisation d'un environnement virtuel Python directement dans le terminal de GitHub Codespaces.
* **Mise en place de l'émulateur :** Installation de LocalStack via le gestionnaire de paquets `pip` et authentification à l'aide d'un jeton (Auth Token) généré sur la plateforme web de LocalStack.
* **Lancement :** Démarrage des services AWS émulés en tâche de fond (`localstack start -d`) et vérification de la disponibilité des services.
* **Outils tiers :** Installation et configuration locale de l'outil `awscli` pour permettre au script de communiquer de manière fluide avec l'émulateur : 
```
curl "[https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip](https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip)" -o "awscliv2.zip"
unzip -q awscliv2.zip && sudo ./aws/install
```
**2. Création de l'instance EC2**
* **Recherche dynamique :** Pour éviter les erreurs liées aux faux identifiants, le script `deploy.sh` interroge d'abord LocalStack (`aws ec2 describe-images`) pour récupérer automatiquement un identifiant d'image système (AMI) valide dans son catalogue.
* **Provisionnement :** Lancement de la création d'un serveur type `t2.micro` en utilisant l'AMI récupérée.
* **Capture de contexte :** Le script extrait et sauvegarde l'identifiant unique de l'instance fraîchement créée (ex: `i-0a23f9...`) afin de le transmettre à la fonction Lambda.

**3. Création des API (+ fonction Lambda)**
* **Code métier (Python) :** Rédaction du script `lambda_function.py` intégrant la bibliothèque `boto3` pour envoyer les ordres de démarrage et d'arrêt. Le code inclut une gestion d'erreur (try/except) pour faciliter le diagnostic en cas d'échec. Le fichier est ensuite compressé au format `.zip`.
* **Gestion des accès (IAM) :** Création d'un rôle de sécurité (`lambda-role`) autorisant le service Lambda à s'exécuter.
* **Déploiement Lambda :** Création de la fonction `PiloteEC2` via le script bash. L'identifiant de l'instance EC2 capturé à l'étape précédente lui est injecté de manière sécurisée via une variable d'environnement (`INSTANCE_ID`).
* **Orchestration API Gateway :** Création d'une API REST nommée `MonAPI`. Configuration d'une méthode `GET` avec une intégration de type `AWS_PROXY` pointant vers la fonction Lambda. L'API est finalement déployée sur un environnement nommé `prod`.

**4. Ouverture des ports et vérification du fonctionnement**
* **Configuration réseau :** Modification de la visibilité du port `4566` (port de communication de LocalStack) dans l'interface de GitHub Codespaces pour le passer de *Privé* à *Public*. Cela lève l'erreur 403 de base et autorise le navigateur à communiquer avec le faux Cloud.
* **Assemblage des routes :** Génération dynamique des URL complètes combinant l'adresse publique du Codespace (le socle) et le chemin d'accès unique créé par l'API Gateway.
* **Validation des tests :** Exécution des requêtes HTTP avec les paramètres `?action=start` et `?action=stop` dans le navigateur, validée par le retour des messages de succès au format JSON (ex: `{"message": "Succès : L'instance a été DÉMARRÉE."}`) : lancer 
```bash
chmod +x deploy.sh
./deploy.sh
```


---------------------------------------------------
Séquence 4 : Documentation  
Difficulté : Facile (~30 minutes)
---------------------------------------------------
**Complétez et documentez ce fichier README.md** pour nous expliquer comment utiliser votre solution.  
Faites preuve de pédagogie et soyez clair dans vos expliquations et processus de travail.  
   
---------------------------------------------------
Evaluation
---------------------------------------------------
Cet atelier, **noté sur 20 points**, est évalué sur la base du barème suivant :  
- Repository exécutable sans erreur majeure (4 points)
- Fonctionnement conforme au scénario annoncé (4 points)
- Degré d'automatisation du projet (utilisation de Makefile ? script ? ...) (4 points)
- Qualité du Readme (lisibilité, erreur, ...) (4 points)
- Processus travail (quantité de commits, cohérence globale, interventions externes, ...) (4 points) 
