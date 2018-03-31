


CREATE FUNCTION vid_trigger() RETURNS trigger AS 
'BEGIN
	INSERT into vid (voter_id) values (NEW.voter_id);
	return NEW;
END;' 
LANGUAGE plpgsql;
 
CREATE TRIGGER vid_trigger BEFORE INSERT ON mvf
     FOR EACH ROW EXECUTE PROCEDURE vid_trigger();

CREATE TRIGGER vid_trigger BEFORE INSERT ON av
     FOR EACH ROW EXECUTE PROCEDURE vid_trigger();
