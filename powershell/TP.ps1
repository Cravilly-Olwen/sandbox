# 1.Preparation du LAB

    # 1.1. Serveur Windows 2025
    
        # Renommer le serveur avec l'identifiant
        Rename-Computer -NewName "SERVEUR-name" -Restart
        # Installation des services
        Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools
        # Création de la forêt et du domaine rt.local
        Install-ADDSForest -DomainName "rt.local" -InstallDNS:$true
        # Installation du service DHCP
        Install-WindowsFeature -Name DHCP -IncludeManagementTools
        # Autoriser le serveur DHCP
        Add-DhcpServerInDC -DnsName "rt.local"
        # Mettre le pool du DHCP
        Add-DhcpServerv4Scope -Name "DHCP-POOL" -StartRange 192.168.1.2 -EndRange 192.168.1.254 -SubnetMask 255.255.255.0 -State Active
        # Configuration des options DHCP
        Set-DhcpServerv4OptionValue -DnsServer 192.168.1.1 -DnsDomain "rt.local"

    # 1.2. Poste client Windows 11

        # Renommer le poste client avec l'identifiant
        Rename-Computer -NewName "CLIENT-name" -DomainCredential rt\Administrateur -Restart
        # Ajouter l'ordinateur au domaine rt.local
        Add-Computer -DomainName "rt.local" -Restart

# 2.Creation d un script PowerShell de creation des comptes

    # 1. Creation de comptes Active Directory

        # Récupération du chemin du fichier CSV pour ajouter des utilisateurs
        $csvPath = "C:\Users\Administrateur\Desktop\users.csv"
         # Vérification de la validité du chemin du fichier avant toute action 
        if (-not(Test-Path -Path $csvPath)) {
            Write-Host "Le fichier CSV n'existe pas à l'emplacement spécifié : $csvPath" -ForegroundColor Red
            exit # Pour arrêter toute action et éviter de continuer pour rien
        }
        # Importation du chemin du fichier CSV 
        $users = Import-Csv -Path $csvPath -Delimiter ";"

        # Parcourt le fichier CSV ligne par ligne pour traiter chaque utilisateur un par un
        foreach ($user in $users) {
            # Regarde si le Login utilisateur existe déjà
            if (Get-ADUser -Filter "SamAccountName -eq '$($user.Login)'") {
                Write-Host "L'utilisateur $($user.Login) existe déjà." -ForegroundColor Red
                continue # Passe à un autre utilisateur
            }
            # Vérifie si le champ OU est manquant ou vide avant de créer l'utilisateur
            if ([string]::IsNullOrWhiteSpace($user.OU)) {
                Write-Host "La colonne OU est vide dans le CSV pour $($user.Login)." -ForegroundColor Red
                continue # Passe à un autre utilisateur
            }
            # Création de l'OU si elle n'existe pas encore dans l'Active Directory "AD"
            $OUPath = "OU=$($user.OU),DC=rt,DC=local"
            $OU = Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$OUPath'"
            if (-not $OU) {
                New-ADOrganizationalUnit -Name "$($user.OU)" -Path "DC=rt,DC=local"
                Write-Host "OU '$($user.OU)' créée avec succès." -ForegroundColor Green
            }
            # Tant qu'on ne saisit pas strictement 'Y/y' ou 'N/n', le script repose la même question.
            while ($true) {
                # Écrire Y/y ou N/n uniquement, sinon ça ne marchera pas
                $choix = Read-Host "Confirmer la création de $($user.Login) dans l'OU $($user.OU) ? (Y/N)"
                # Si on a écrit N/n, ça annulera la création du compte
                if ($choix -eq 'N' -or $choix -eq 'n') {
                    Write-Host "Création annulée pour $($user.Login)." -ForegroundColor Red
                    break # Pour sortir de la boucle while et passer à un autre utilisateur
                # Si on a écrit Y/y, ça fait la création du compte
                } elseif ($choix -eq 'Y' -or $choix -eq 'y') {
                    # Mot de passe du compte utilisateur par défaut
                    $password = ConvertTo-SecureString "P@ssword2026!" -AsPlainText -Force
                    # Hashtable "Table de hachage"
                    $UserParams= @{
                        'Name'                  = $user.Prenom + ' ' + $user.Nom
                        'SamAccountName'        = $user.Login
                        'UserPrincipalName'     = $user.Login + '@rt.local'
                        'Path'                  = $OUPath
                        'AccountPassword'       = $password
                        'Enabled'               = $true
                        'ChangePasswordAtLogon' = $true
                    }
                    # Création de l'utilisateur avec les informations du hashtable
                    New-ADUser @UserParams
                    Write-Host "L'utilisateur $($user.Login) a été créé." -ForegroundColor Green
                    break # Pour sortir de la boucle while et passer à un autre utilisateur
                # Signalement d'une mauvaise interaction lors de la saisie sur le TERMINAL
                }else {
                    Write-Host "Veuillez bien choisir Y/y ou N/n" -ForegroundColor RED            
                }
            }
        }

    # 2. Gestion des dossiers utilisateurs

        # Installation du module si ce n'est pas déjà fait pour éviter les conflits
        Install-Module -Name NTFSSecurity -Force
        # Importation du module NTFS pour pouvoir manipuler les droits des dossiers
        Import-Module NTFSSecurity

        # Récupération du chemin du fichier CSV pour ajouter des utilisateurs
        $csvPath = "C:\Users\Administrateur\Desktop\users.csv"
        # Vérification de la validité du chemin du fichier avant toute action 
        if (-not(Test-Path -Path $csvPath)) {
            Write-Host "Le fichier CSV n'existe pas à l'emplacement spécifié : $csvPath" -ForegroundColor Red
            exit # Pour arrêter toute action et éviter de continuer pour rien
        }
        # Importation du chemin du fichier CSV 
        $users = Import-Csv -Path $csvPath -Delimiter ";"

        # Parcourt le fichier CSV ligne par ligne pour traiter chaque utilisateur un par un
        foreach ($user in $users) {
            # Vérifie l'existence de l'OU et du compte dans l'Active Directory avant de créer le dossier
            $OUPath = "OU=$($user.OU),DC=rt,DC=local"
            $OU = Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$OUPath'"
            $AD = Get-ADUser -Filter "SamAccountName -eq '$($user.Login)'"
            if (-not $OU -or -not $AD) {
                Write-Host "L'utilisateur $($user.Login) n'est pas créé donc le dossier n'a pas pu être ajouté"
                continue # Passe à un autre utilisateur
            }
            # Vérifie si le dossier de l'utilisateur existe déjà
            if (Test-Path -Path "C:\UsersData\$($user.Login)") {
                Write-Host "Le dossier de $($user.Login) existe déjà ici C:\UsersData\$($user.Login)." -ForegroundColor Green
            }
            # Si le dossier n'existe pas, on le crée et on lui attribue les droits NTFS "Modify : Lire - Écrire - Exécuter - Supprimer"
            else {
                New-Item -Path "C:\UsersData\$($user.Login)" -ItemType Directory
                Add-NTFSAccess -Path "C:\UsersData\$($user.Login)" -Account "rt\$($user.Login)" -AccessRights Modify
                Write-Host "Le dossier de $($user.Login) a été créé ici C:\UsersData\$($user.Login)." -ForegroundColor Green
            }
        }

    # 3. Suppression de comptes utilisateurs

        # Récupération du chemin du fichier CSV pour supprimer des utilisateurs
        $csvPathDelete = "C:\Users\Administrateur\Desktop\users_delete.csv"
        # Vérification de la validité du chemin du fichier avant toute action 
        if (-not(Test-Path -Path $csvPathDelete)) {
            Write-Host "Le fichier CSV n'existe pas à l'emplacement spécifié : $csvPathDelete" -ForegroundColor Red
            exit # Pour arrêter toute action et éviter de continuer pour rien
        }
        # Importation du chemin du fichier CSV 
        $users_delete = Import-Csv -Path $csvPathDelete -Delimiter ";"

        # Parcourt le fichier CSV ligne par ligne pour traiter chaque utilisateur un par un
        foreach ($user in $users_delete) {
            # Vérification du compte dans l'Active Directory "AD" avant sa suppression
            $compte = Get-ADUser -Filter "SamAccountName -eq '$($user.Login)'"  
            if ($compte) {
                Remove-ADUser -Identity "$($user.Login)" -Confirm:$false
                Write-Host "Le compte $($user.Login) a été supprimé avec succès !" -ForegroundColor Green
            }
            # Avertissement si l'utilisateur n'est pas dans l'Active Directory "AD"
            else {
                Write-Host "Le compte $($user.Login) est introuvable dans l'Active Directory !" -ForegroundColor Red
            }
        }

    # 4. Archivage des dossiers utilisateurs (sécurité)

        # Récupération du chemin du fichier CSV pour supprimer des utilisateurs
        $csvPathDelete = "C:\Users\Administrateur\Desktop\users_delete.csv"
        # Vérification de la validité du chemin du fichier avant toute action 
        if (-not(Test-Path -Path  $csvPathDelete)) {
            Write-Host "Le fichier CSV n'existe pas à l'emplacement spécifié : $csvPathDelete" -ForegroundColor Red
            exit # Pour arrêter toute action et éviter de continuer pour rien
        }
        # Récupération de la date actuelle dans une variable
        $Date = Get-Date -Format "yyyyMMdd"
        # Chemin où se trouve le dossier d'archive pour les dossiers utilisateurs à supprimer
        $Archive = "C:\Archives"
        # Vérification de la validité du dossier avant toute action 
        if (-not(Test-Path -Path $Archive)) {
            New-Item -Path $Archive -ItemType Directory
            Write-Host "Le dossier d'archive a été créé à l'emplacement : $Archive" -ForegroundColor Green
        }
        # Importation du chemin du fichier CSV 
        $users_delete = Import-Csv -Path $csvPathDelete -Delimiter ";"

        # Parcourt le fichier CSV ligne par ligne pour traiter chaque utilisateur un par un
        foreach ($user in $users_delete) {
            # Définition des chemins : dossier source à archiver et destination du fichier ZIP
            $Path = "C:\UsersData\$($user.Login)"
            $Zip = "$Archive\$($user.Login)_$Date.zip"
            # Vérifie que l'archive a bien été créée avant de supprimer le dossier original
            if (Test-Path -Path $Path) {
                Compress-Archive -Path "$Path" -DestinationPath "$Zip" -Force
                # Regarde si le ZIP existe et ensuite supprime le dossier de l'utilisateur
                if (Test-Path -Path $Zip) {
                    Remove-Item -Path $Path -Recurse -Force
                    Write-Host "Archive créée dans $Zip et dossier original supprimé." -ForegroundColor Green
                }
                # Message d'erreur si la compression a échoué
                else {
                    Write-Host "Le fichier ZIP n'a pas pu être généré : $Path . Vérifiez que le dossier n'est pas vide." -ForegroundColor Red
                }
            }
            # Avertissement si l'utilisateur n'avait pas de dossier personnel à archiver
            else {
                Write-Host "Le dossier source $Path n'existe pas." -ForegroundColor Red
            }
        }