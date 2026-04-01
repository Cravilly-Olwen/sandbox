# 2.Creation d un script PowerShell de creation des comptes    

    # 5. Parametrage du script et 6. Gestion des erreurs et messages

        <#
        # Le Script marche si ces modules sont bien installés préalablement
        Install-Module -Name NTFSSecurity -Force
        Import-Module NTFSSecurity
        #>

        [CmdletBinding(SupportsShouldProcess = $true)]

        # Paramétrage global et variables de configuration
        param (
            [Parameter(Mandatory = $true)]
            [ValidateSet('Create', 'Delete')]
            [string]$Action,

            [Parameter(Mandatory = $true)]
            [string]$CsvPath, 

            [string]$LogPath = "C:\log",
            [string]$UsersDataPath = "C:\UsersData",
            [string]$ArchivePath = "C:\Archives",
            [string]$DC = "DC=rt,DC=local",
            [string]$Password = "P@ssword2026!"
        )

        # Récupération de la date actuelle dans une variable
        $Date = Get-Date -Format "yyyyMMdd"       
        # Vérification de la validité du dossier log avant toute action  
        if (-not (Test-Path -Path $LogPath )) {
            New-Item -Path $LogPath -ItemType Directory
            Write-Host "Le dossier a été ajouté ici $LogPath !" -ForegroundColor Green
        }
        # Création du fichier de log avec la variable
        $LogFile = "$LogPath\Log_$Date.txt"
        # Vérification de la validité du chemin du fichier avant toute action 
        if (-not(Test-Path -Path $CsvPath)){
            # Horodatage et écriture de l'action dans le fichier de log (traçabilité).
            $msg = "Le fichier CSV n'existe pas à l'emplacement spécifié : $CsvPath"
            Write-Host $msg -ForegroundColor Red
            Add-Content -Path $LogFile -Value "$Date - ERREUR : $msg"
            exit # Pour arrêter toute action et éviter de continuer pour rien
        }
        # Importation du chemin du fichier CSV     
        $users = Import-Csv -Path $CsvPath -Delimiter ";"
        # Mot de passe du compte utilisateur par défaut
        $passwordSecure = ConvertTo-SecureString $Password -AsPlainText -Force
        # Vérification de la validité du dossier avant toute action
        if (-not(Test-Path -Path $ArchivePath)) {
            New-Item -Path $ArchivePath -ItemType Directory
            # Horodatage et écriture de l'action dans le fichier de log (traçabilité).
            $msg = "Le dossier d'archive a été créé à l'emplacement : $ArchivePath"
            Write-Host $msg -ForegroundColor Green
            Add-Content -Path $LogFile -Value "$Date - INFO : $msg"
        }

        # Action pour créer un utilisateur
        if ( $Action -eq "Create" ) {
            # Parcourt le fichier CSV ligne par ligne pour traiter chaque utilisateur un par un
            foreach ($user in $users) {
                # Regarde si le Login utilisateur existe déjà
                if (Get-ADUser -Filter "SamAccountName -eq '$($user.Login)'") {
                    # Horodatage et écriture de l'action dans le fichier de log (traçabilité).
                    $msg = "L'utilisateur $($user.Login) existe déjà."
                    Write-Host $msg -ForegroundColor Red
                    Add-Content -Path $LogFile -Value "$Date - ERREUR : $msg"
                    continue # Passe à un autre utilisateur
                }
                # Vérifie si le champ OU est manquant ou vide avant de créer l'utilisateur
                if ([string]::IsNullOrWhiteSpace($user.OU)) {
                    # Horodatage et écriture de l'action dans le fichier de log (traçabilité).
                    $msg = "La colonne OU est vide dans le CSV pour $($user.Login)."
                    Write-Host $msg -ForegroundColor Red
                    Add-Content -Path $LogFile -Value "$Date - ERREUR : $msg"
                    continue # Passe à un autre utilisateur
                }
                # Création de l'OU si elle n'existe pas encore dans l'Active Directory "AD"
                $OUPath = "OU=$($user.OU),$DC"
                $OU = Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$OUPath'"
                if (-not $OU) {
                     # En mode -WhatIf, affiche l'action sans créer l'OU réellement
                     if ($PSCmdlet.ShouldProcess("$($user.OU)", "Créer l'OU")) {
                        New-ADOrganizationalUnit -Name "$($user.OU)" -Path $DC
                        # Horodatage et écriture de l'action dans le fichier de log (traçabilité).
                        $msg = "OU '$($user.OU)' créée avec succès."
                        Write-Host $msg -ForegroundColor Green
                        Add-Content -Path $LogFile -Value "$Date - INFO : $msg"
                    }
                }
                # En mode -WhatIf, affiche l'action sans créer le compte ni demander la confirmation Y/N
                if ($PSCmdlet.ShouldProcess("$($user.Login)", "Créer l'utilisateur")) {
                    # Tant qu'on ne saisit pas strictement 'Y/y' ou 'N/n', le script repose la même question.
                    while ($true) {
                        # Écrire Y/y ou N/n uniquement, sinon ça ne marchera pas
                        $choix = Read-Host "Confirmer la creation de $($user.Login) dans l'OU $($user.OU) ? (Y/N)"
                        if ($choix -eq 'N' -or $choix -eq 'n') {
                            # Horodatage et écriture de l'action dans le fichier de log (traçabilité).
                            $msg = "Création annulée pour $($user.Login)."
                            Write-Host $msg -ForegroundColor Red
                            Add-Content -Path $LogFile -Value "$Date - ANNULATION : $msg"
                            break # Pour sortir de la boucle while et passer à un autre utilisateur
                        # Si on a écrit Y/y, ça fait la création du compte
                        } elseif ($choix -eq 'Y' -or $choix -eq 'y') {
                            # Hashtable "Table de hachage"
                            $UserParams = @{
                                'Name' = $user.Prenom + ' ' + $user.Nom
                                'SamAccountName' = $user.Login
                                'UserPrincipalName' = $user.Login + '@rt.local'
                                'GivenName' = $user.Prenom
                                'Surname'   = $user.Nom
                                'Path' = $OUPath
                                'AccountPassword' = $passwordSecure
                                'Enabled' = $true
                                'ChangePasswordAtLogon' = $true
                            }
                            # Création de l'utilisateur avec les informations du hashtable
                            New-ADUser @UserParams
                            # Horodatage et écriture de l'action dans le fichier de log (traçabilité).
                            $msg = "L'utilisateur $($user.Login) a été créé."
                            Write-Host $msg -ForegroundColor Green
                            Add-Content -Path $LogFile -Value "$Date - SUCCES : $msg"
                            break # Pour sortir de la boucle while et passer à un autre utilisateur
                        # Signalement d'une mauvaise interaction lors de la saisie sur le TERMINAL
                        } else {
                            # Horodatage et écriture de l'action dans le fichier de log (traçabilité).
                            $msg = "Veuillez bien choisir Y/y ou N/n"
                            Write-Host $msg -ForegroundColor RED            
                            Add-Content -Path $LogFile -Value "$Date - ERREUR : $msg"
                        }
                    }
                }
            }
            # Parcourt le fichier CSV ligne par ligne pour traiter chaque utilisateur un par un
            foreach ($user in $users) {
                # Vérifie l'existence de l'OU et du compte dans l'Active Directory avant de créer le dossier
                $OUPath = "OU=$($user.OU),$DC"
                $OU = Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$OUPath'"
                $AD = Get-ADUser -Filter "SamAccountName -eq '$($user.Login)'"
                if (-not $OU -or -not $AD){
                    # Horodatage et écriture de l'action dans le fichier de log (traçabilité).
                    $msg = "L'utilisateur $($user.Login) n'est pas créé donc le dossier n'a pas pu être ajouté"
                    Write-Host $msg
                    Add-Content -Path $LogFile -Value "$Date - ERREUR : $msg"
                    continue # Passe à un autre utilisateur
                }
                # Vérifie si le dossier de l'utilisateur existe déjà
                if (Test-Path -Path "$UsersDataPath\$($user.Login)") {
                    # Horodatage et écriture de l'action dans le fichier de log (traçabilité).
                    $msg = "Le dossier de $($user.Login) existe déjà ici $UsersDataPath\$($user.Login)."
                    Write-Host $msg -ForegroundColor Green
                    Add-Content -Path $LogFile -Value "$Date - INFO : $msg"
                }
                # Si le dossier n'existe pas, on le crée et on lui attribue les droits NTFS "Modify : Lire - Écrire - Exécuter - Supprimer"
                else {
                    # En mode -WhatIf, affiche l'action sans créer le dossier ni modifier les droits NTFS
                    if ($PSCmdlet.ShouldProcess("$UsersDataPath\$($user.Login)", "Créer le dossier et attribuer les droits")) {
                        New-Item -Path "$UsersDataPath\$($user.Login)" -ItemType Directory
                        Add-NTFSAccess -Path "$UsersDataPath\$($user.Login)" -Account "rt\$($user.Login)" -AccessRights Modify
                        # Horodatage et écriture de l'action dans le fichier de log (traçabilité).
                        $msg = "Le dossier de $($user.Login) a été créé ici $UsersDataPath\$($user.Login)."
                        Write-Host $msg -ForegroundColor Green
                        Add-Content -Path $LogFile -Value "$Date - SUCCES : $msg"
                    }
                }
            }
        }

        # Action pour supprimer un utilisateur
        if ( $Action -eq "Delete" ) {
            # Parcourt le fichier CSV ligne par ligne pour traiter chaque utilisateur un par un
            foreach ($user in $users) {
                # Définition des chemins : dossier source à archiver et destination du fichier ZIP
                $Path = "$UsersDataPath\$($user.Login)"
                $Zip = "$ArchivePath\$($user.Login)_$Date.zip"
                # Vérifie que l'archive a bien été créée avant de supprimer le dossier original
                if (Test-Path -Path $Path) {
                    # En mode -WhatIf, affiche l'action sans compresser ni supprimer le dossier
                    if ($PSCmdlet.ShouldProcess("$($user.Login)", "Archiver et supprimer le dossier")) {
                        Compress-Archive -Path "$Path" -DestinationPath "$Zip" -Force
                        # Regarde si le ZIP existe et ensuite supprime le dossier de l'utilisateur
                        if (Test-Path -Path $Zip) {
                        Remove-Item -Path $Path -Recurse -Force
                        # Horodatage et écriture de l'action dans le fichier de log (traçabilité).
                        $msg = "Archive créée dans $Zip et dossier original supprimé."
                        Write-Host $msg -ForegroundColor Green
                        Add-Content -Path $LogFile -Value "$Date - SUCCES : $msg"
                        }
                        # Message d'erreur si la compression a échoué
                        else {
                            # Horodatage et écriture de l'action dans le fichier de log (traçabilité).
                        $msg = "Le fichier ZIP n'a pas pu être généré : $Path . Vérifiez que le dossier n'est pas vide."
                            Write-Host $msg -ForegroundColor Red
                            Add-Content -Path $LogFile -Value "$Date - ERREUR : $msg"
                        }
                    }
                }
                # Avertissement si l'utilisateur n'avait pas de dossier personnel à archiver
                else {
                    # Horodatage et écriture de l'action dans le fichier de log (traçabilité).
                    $msg = "Le dossier source $Path n'existe pas."
                    Write-Host $msg -ForegroundColor Red
                    Add-Content -Path $LogFile -Value "$Date - ERREUR : $msg"
                }
            }
            # Parcourt le fichier CSV ligne par ligne pour traiter chaque utilisateur un par un
            foreach ($user in $users) {
                # Vérification du compte dans l'Active Directory "AD" avant sa suppression
                $compte = Get-ADUser -Filter "SamAccountName -eq '$($user.Login)'"
                if ($compte) {
                    # En mode -WhatIf, affiche l'action sans supprimer le compte de l'AD
                    if ($PSCmdlet.ShouldProcess("$($user.Login)", "Supprimer le compte AD")) {
                        Remove-ADUser -Identity "$($user.Login)" -Confirm:$false
                        # Horodatage et écriture de l'action dans le fichier de log (traçabilité).
                        $msg = "Le compte $($user.Login) a été supprimé avec succès !"
                        Write-Host $msg -ForegroundColor Green
                        Add-Content -Path $LogFile -Value "$Date - SUCCES : $msg"
                    }
                }
                # Avertissement si l'utilisateur n'est pas dans l'Active Directory "AD"
                else {
                    # Horodatage et écriture de l'action dans le fichier de log (traçabilité).
                    $msg = "Le compte $($user.Login) est introuvable dans l'Active Directory !"
                    Write-Host $msg -ForegroundColor Red
                    Add-Content -Path $LogFile -Value "$Date - ERREUR : $msg"
                }
            }
        }
                
# Commande pour le lancement du script DELETE ou CREATE
<#
# Exécution des commandes en mode SIMULATION (Test) grâce à -WhatIf pour ajouter des utilisateurs :
.\Manage-ADUsers.ps1 -Action Create -CsvPath "C:\votre_chemin\votre_fichier.csv" -WhatIf

# Exécution des commandes en mode SIMULATION (Test) grâce à -WhatIf pour supprimer des utilisateurs :
.\Manage-ADUsers.ps1 -Action Delete -CsvPath "C:\votre_chemin\votre_fichier.csv" -WhatIf

# Exécution des commandes en mode RÉEL pour ajouter des utilisateurs :
.\Manage-ADUsers.ps1 -Action Create -CsvPath "C:\votre_chemin\votre_fichier.csv"

# Exécution des commandes en mode RÉEL pour supprimer des utilisateurs :
.\Manage-ADUsers.ps1 -Action Delete -CsvPath "C:\votre_chemin\votre_fichier.csv"
#>