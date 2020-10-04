import jenkins.model.*
import hudson.security.*
import org.jenkinsci.plugins.*

String server = env.LDAP_BIND_USER;
String rootDN = 'o=mllrjb.com';
String userSearchBase = '';
String userSearch = 'uid={0}';
String groupSearchBase = 'ou=Groups';
String bindDn = env.LDAP_BIND_USER;
String bindPassword = env.LDAP_BIND_PASSWORD;
boolean inhibitInferRootDN = false;

SecurityRealm ldap_realm = new LDAPSecurityRealm(server, rootDN, userSearchBase, userSearch, groupSearchBase, bindDn, bindPassword, inhibitInferRootDN) 
Jenkins.instance.setSecurityRealm(ldap_realm)
Jenkins.instance.save()