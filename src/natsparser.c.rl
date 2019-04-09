#include <stdint.h>

%%{

machine nats;

access parser->;

action hello_fin {
    parser->cb(parser->user_data);
}

main := 'Hello' @hello_fin;

write data;

}%%

struct natsparser_s {
    int (*cb)(void * user_data);
    int cs;
    void * user_data;
};


int natsparser_init (
    struct natsparser_s * parser
)
{
    %% write init;

    return 0;
}


int natsparser_parse (
    struct natsparser_s * parser,
    char * buf,
    int buf_len
) {

    char * p = buf;
    char * pe = buf + buf_len;

    %% write exec;

    if (parser->cs >= %%{ write first_final; }%%) {
        return 1;
    }

    if (%%{ write error; }%% == parser->cs) {
        return -1;
    }

    return 0;
};
