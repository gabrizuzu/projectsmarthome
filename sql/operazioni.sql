#operazione 1: dispositivo più usato    
DROP PROCEDURE IF EXISTS DispositivoMostUsed;
DELIMITER $$
CREATE PROCEDURE DispositivoMostUsed()
BEGIN


    SELECT ID.NomeUtente, ID.CodiceDispositivo, COUNT(CodiceDispositivo) AS NumeroUtilizzi
        FROM ImpostazioniDispositivo ID
        NATURAL JOIN (
        SELECT NomeUtente, MAX(NumeroUtilizzi) AS MaxUtilizzi
		FROM
        (
			SELECT ID.NomeUtente, ID.CodiceDispositivo, COUNT(CodiceDispositivo) AS NumeroUtilizzi
			FROM ImpostazioniDispositivo ID
			GROUP BY ID.NomeUtente, ID.CodiceDispositivo
        ) as K
        GROUP BY NomeUtente) as M
        
        WHERE ID.NumeroUtilizzi = M.MaxUtilizzi
        GROUP BY ID.NomeUtente, ID.CodiceDispositivo;
END $$
delimiter ;
    
#operazione 2: creazione di un nuovo account 		
drop procedure if exists CreazioneAccount;
delimiter $$
create procedure CreazioneAccount ( 
                                  in cognome varchar(20), 
								in codicefiscale varchar(40),
                                    in datanascita date, --
                                    in telefono double, --
                                    in nomeutente varchar(40), 
                                    in password varchar(40), 
                                    in domanda varchar(255), 
                                    in risposta varchar(255), 
                                    in tipologia varchar(40), 
                                    in scadenza date, 
                                    in ente varchar(40), 
                                    in nome varchar(10),
                                    in dataiscrizione date,
                                    in numerodocumento varchar(10))
begin 
    
    if datediff(current_date, scadenza) < 0 && (length(password) > 9 && length(nomeutente) > 5) then 
		begin 
        insert into Utente values (cognome,nome,datanascita, telefono,dataiscrione,codfiscale,tipologia,numdocumento);
        insert into Documento values (tipologia,numdocumento,scadenza,ente);
        insert into Account values (nomeutente,password,domandasicurezza,rispostasicurezza);
			
        end ; 
	else 
    signal sqlstate '45000'
    set message_text='Errore, input non valido. Inserire una password lunga almeno 10 caratteri, un nome utente lungo almeno 6 caratteri e/o un documento valido';
	end if;

end $$
delimiter ; 

#operazione 3: Calcolo Consumo Mensile
drop procedure if exists CalcoloConsumo;
delimiter $$
create procedure CalcoloConsumo(in _nomeutente varchar(40), in _mese timestamp, out consumo_ int)
begin
declare consumo_ int;
SELECT SUM(ConsumoDispositivo) as D 
FROM ImpostazioniDispositivo
WHERE NomeUtente=_nomeutente AND Month(TimestampInizio)=_mese;

SELECT SUM(ConsumoLuce) as L
FROM RegolazioneLuce
WHERE NomeUtente=_nomeutente AND Month(TimestampInizio)=_mese;

SELECT SUM(ConsumoClima) as C
FROM ImpostazioneClima
WHERE NomeUtente=_nomeutente AND Month(TimestampInizio)=_mese;

set consumo_= D + L + C;
end $$
delimiter ;

#operazione 4: Operazione che restituisce l'account più attivo in un determinato mese
drop procedure if exists account_frequente;
delimiter $$
create procedure account_frequente(in _MMYY timestamp)
    begin
    select CodiceAccount
    from GestoreCentrale
	where MONTH(TimestampInizio)=MONTH(_MMYY)
    AND YEAR(TimestampInizio)=YEAR(_MMYY)
    group by CodiceAccount
    having count(*) >= all (select count(*)
							from GestoreCentrale
							group by CodiceAccount)
	order by CodiceAccount;
end $$;
delimiter ;

#operazione 5: Operazione che permette di configurare una luce da remoto
drop procedure if exists settaggio_luci;
delimiter $$
create procedure settaggio_luci (in _nomeUtente varchar(20), in _codiceluce int, in_intensità int, in _tempcolore int)
    begin
    DECLARE ultimaimpostazione TIMESTAMP;
    DECLARE fine TIMESTAMP;
    SET ultimaimpostazione=(SELECT TimestampInizio FROM RegolazioneLuce WHERE TimestampInizio >=(SELECT TimestampInizio FROM RegolazioneLuce WHERE CodLuce=_codiceluce));
    SET fine=(SELECT TimestampFine FROM GestoreCentrale WHERE TimestampInizio=_ultimaimpostazione);
    IF fine=NULL #se l'ultima impostazione non è ancora finita
    THEN
    UPDATE GestoreCentrale
    SET TimestampFine=CURRENT_TIMESTAMP#fine della vecchia impostazione
    WHERE TimestampInizio=ultimaimpostazione;
    END IF;
    insert into GestoreCentrale(NomeUtente,TimestampInizio,TimestampFine,PartenzaDifferita)#RICORDATI CONSUMO EVENTUALMENTE
    VALUES(_nomeUtente,CURRENT_TIMESTAMP,NULL,"No");
INSERT INTO RegolazioneLuce (NomeUtente,TimestampInizio,CodiceLuce,TimestampInizio,Intensità,TempColore)
VALUES (_nomeUtente,CURRENT_TIMESTAMP,_codiceluce, CURRENT_TIMESTAMP, _intensità, _tempcolore);
end $$;
delimiter ;

#operazione 6:leggere l'ultimo utilizzo di un utente
drop procedure if exists UltimoUtilizzo ;
delimiter $$
create procedure UltimoUtilizzo(IN _NomeUtente INTEGER)
begin
    SELECT TimestampFine
	FROM GestoreCentrale
	WHERE NomeUtente=_NomeUtente AND TimestampFine >= (SELECT TimestampFine 
														FROM GestoreCentrale);
end $$
delimiter ; 

#operazione 7: Calcolo produzione relativa ad una fascia oraria 
drop procedure if exists CalcoloProduzioneRIDONDANTE;
delimiter $$
create procedure CalcoloProduzioneRIDONDANTE(in _CodFascia int, in _Data TIMESTAMP, out ProduzioneFascia_ int)
begin
SELECT Valore
FROM Contatore
WHERE Data=_Data AND CodFascia=_CodFascia;
end $$
delimiter ;

#operazione 8: creare un'impostazione relativa al clima
drop procedure if exists ImpostazioneClimatizzatore;
delimiter $$
create procedure ImpostazioneClimatizzatore(in _nomeutente  varchar(40),in _CodClimatizzatore int, in _Temperatura int, _Umidità int)
begin 
insert into GestoreCentrale(NomeUtente,TimestampInizio,TimestampFine,PartenzaDifferita)
    values(_nomeUtente,CURRENT_TIMESTAMP,NULL,"No");
insert into ImpostazioneClima(NomeUtente, TimestampInizio, CodClimatizzatore,Temperatura,Umidità)
		values (_nomeutente,CURRENT_TIMESTAMP,_CodClimatizzatore,_Temperatura,_Umidità);
end $$
delimiter ;