/**
 * @displayName EmailSender
 * @output true
 * @author judachury
 */
component accessors="true" {

    property name="provider";
    
    CONS.PROVIDER = 'cm';

    public function init (string provider = CONS.PROVIDER) {
        if (structKeyExists(application.config, arguments.provider)) {
            This.setProvider( variables.initializeProvider(arguments.provider) );
        } else {
            throw('configuration for provider has not been setup in the application', 'EmailProviderNotConfigured');
        }
    }

    public function send(required string emailId, required array email, struct data = StructNew('ordered'), subscribe = false, tracking = 'Unchanged') {
        lock timeout="10" scope="request" {
            var rsq = serializeJSON({
                'to': arguments.email,
                'data': arguments.data,
                'AddRecipientsToList': arguments.subscribe,
                'ConsentToTrack': arguments.tracking//add a space if no or yes is sent to make it string, otherwise it becames boolean
            });
            
            return variables.provider.sendSmartEmail(arguments.emailId, rsq);
        }
    }

    private function initializeProvider(provider) {
        try {
            switch (arguments.provider) {
                case 'cm':
                    return new cfc.CampaignMonitor.TransactionalHttpRequest(
                        Application.Config.cm.apikey, 
                        Application.Config.cm.url,
                        Application.name
                    );
                break;
                default:
                    throw('Provider not supported', 'EmailProviderNotSupported');
                break;
            }
        } catch (any ex) {
            throw('Configuration details for provider has not been setup in the application', 'EmailProviderNotConfigured');
        }
    }
}